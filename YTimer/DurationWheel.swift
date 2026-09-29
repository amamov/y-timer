import SwiftUI
import UIKit

/// 기본 시계 앱처럼 시·분·초를 한 휠에서 굴린다.
/// 선택 띠는 하나로 이어지고, 단위 글자는 숫자 바로 오른쪽에 고정된다.
struct DurationWheel: UIViewRepresentable {
    @Binding var seconds: Int

    private static let perMinute = TimerLimits.secondsPerMinute
    private static let perHour = perMinute * perMinute
    static let columns: [(range: ClosedRange<Int>, unit: String)] = [
        (0...TimerLimits.maxHours, "시간"),
        (0...(perMinute - 1), "분"),
        (0...(perMinute - 1), "초"),
    ]

    func makeUIView(context: Context) -> DurationPickerView {
        let view = DurationPickerView(columns: Self.columns)
        view.onChange = { values in
            seconds = values[0] * Self.perHour + values[1] * Self.perMinute + values[2]
        }
        return view
    }

    func updateUIView(_ view: DurationPickerView, context: Context) {
        view.select([seconds / Self.perHour, seconds % Self.perHour / Self.perMinute, seconds % Self.perMinute])
    }
}

final class DurationPickerView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    private let picker = UIPickerView()
    private let columns: [(range: ClosedRange<Int>, unit: String)]
    private var unitLabels: [UILabel] = []
    private let rowHeight: CGFloat = 40
    /// 숫자 오른쪽 끝과 단위 글자 사이.
    private let gap: CGFloat = 6
    var onChange: (([Int]) -> Void)?

    private static let numberFont = UIFont.rounded(size: 24, weight: .regular)
    private static let unitFont = UIFont.rounded(size: 17, weight: .semibold)

    init(columns: [(range: ClosedRange<Int>, unit: String)]) {
        self.columns = columns
        super.init(frame: .zero)
        picker.dataSource = self
        picker.delegate = self
        addSubview(picker)
        unitLabels = columns.map { column in
            let label = UILabel()
            label.text = column.unit
            label.font = Self.unitFont
            label.textColor = UIColor.white.withAlphaComponent(0.55)
            label.isUserInteractionEnabled = false
            addSubview(label)
            return label
        }
    }

    required init?(coder: NSCoder) { fatalError("코드로만 만든다") }

    func select(_ values: [Int]) {
        for (component, value) in values.enumerated() where picker.selectedRow(inComponent: component) != value - columns[component].range.lowerBound {
            picker.selectRow(value - columns[component].range.lowerBound, inComponent: component, animated: false)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        picker.frame = bounds
        picker.layoutIfNeeded()
        placeUnits()
        // 휠이 처음 그려진 뒤에야 칸 위치가 정해지므로 한 번 더 맞춘다.
        DispatchQueue.main.async { [weak self] in self?.placeUnits() }
    }

    /// 선택된 숫자 칸의 실제 위치를 읽어, 칸 가운데(숫자 오른쪽 끝) 바로 오른쪽에 단위를 둔다.
    private func placeUnits() {
        for (component, label) in unitLabels.enumerated() {
            guard let cell = picker.view(forRow: picker.selectedRow(inComponent: component), forComponent: component) else { continue }
            let frame = cell.convert(cell.bounds, to: self)
            label.sizeToFit()
            label.frame.origin = CGPoint(x: frame.midX + gap / 2, y: bounds.midY - label.bounds.height / 2)
        }
    }

    private var columnWidth: CGFloat { (bounds.width - 24) / CGFloat(columns.count) }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { columns.count }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        columns[component].range.count
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat { columnWidth }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { rowHeight }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let cell = (view as? NumberCell) ?? NumberCell(font: Self.numberFont, gap: gap)
        cell.text = "\(columns[component].range.lowerBound + row)"
        return cell
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        placeUnits()
        onChange?(columns.indices.map { columns[$0].range.lowerBound + pickerView.selectedRow(inComponent: $0) })
    }
}

/// 숫자는 칸 가운데를 오른쪽 끝선으로 삼아 붙는다.
private final class NumberCell: UIView {
    private let label = UILabel()
    private let gap: CGFloat

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    init(font: UIFont, gap: CGFloat) {
        self.gap = gap
        super.init(frame: .zero)
        label.font = font
        label.textColor = .white
        label.textAlignment = .right
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError("코드로만 만든다") }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 0, y: 0, width: bounds.width / 2 - gap / 2, height: bounds.height)
    }
}

private extension UIFont {
    static func rounded(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = base.fontDescriptor.withDesign(.rounded)?
            .addingAttributes([.featureSettings: [[
                UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
            ]]]) ?? base.fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }
}
