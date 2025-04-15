//
//  RoundedCorner.swift
//  Wafid
//
//  Created by almedadsoft on 09/04/2025.
//


import SwiftUI

// امتداد للعمل مع التواريخ
extension Date {
    func FormatterToString(_ format: String, _ locale: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: locale)
        return dateFormatter.string(from: self)
    }
    
    // إضافة دالة للحصول على تاريخ الشهر السابق أو التالي
    func byAddingMonths(_ months: Int, calendar: Calendar = Calendar.current) -> Date {
        return calendar.date(byAdding: .month, value: months, to: self) ?? self
    }
}

// امتداد للتعامل مع تقريب زوايا محددة في الـ View
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// شكل مخصص لتقريب زوايا محددة
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// ثوابت الألوان والتصميم
struct CalendarConstants {
    static let lineColor = Color(red: 0.14, green: 0.24, blue: 0.36) // لون أزرق داكن
    static let backgroundColor = Color(red: 0.92, green: 0.93, blue: 0.95) // لون رمادي فاتح
    static let todayColor = Color(red: 0.02, green: 0.2, blue: 0.41) // لون أزرق داكن
    static let weekdayTextColor = Color(red: 0.64, green: 0.73, blue: 0.87) // لون أزرق فاتح
    
    // ثوابت التمرير الصفحي
    static let monthsToShow = 100 // عدد الشهور للعرض (12 شهر سابق و12 شهر حالي ومستقبلي)
    static let initialPageIndex = 12 // مؤشر البداية (للشهر الحالي)
    static let monthPadding: CGFloat = 16 // المسافة بين الشهور
    static let animationDuration = 0.3 // مدة الحركة الانتقالية
    
    // ثوابت ارتفاع التقويم
    static let monthGridHeight: CGFloat = 280 // ارتفاع عرض الشهر
}

// عرض التقويم المحسن مع ميزة التمرير
struct CustomCalendarView: View {
    // MARK: - المتغيرات العامة
    @Binding var selectedDate: Bool?
    @Binding var selectedDateRange: ClosedRange<Date>?
    let onSave: (ClosedRange<Date>?) -> Void
    
    // MARK: - المتغيرات الداخلية
    @State private var currentPageIndex = CalendarConstants.initialPageIndex
    @State private var tempStartDate: Date?
    @State private var tempEndDate: Date?
    @State private var months: [Date] = []
    
    // MARK: - الثوابت
    // ترتيب أيام الأسبوع بشكل صحيح (من الأحد للسبت بالترتيب العربي)
    private let weekDayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
    // إعداد التقويم باستخدام توقيت UTC
    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()
    
    // تحديد اليوم الحالي في التقويم UTC
    private let today: Date = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar.startOfDay(for: Date())
    }()
    
    // المؤشر للتمرير الصفحي
    @State private var pageIndex = CalendarConstants.initialPageIndex
    
    // MARK: - Initialization
    // مهيئ للتقويم
    init(selectedDate: Binding<Bool?>, selectedDateRange: Binding<ClosedRange<Date>?>, onSave: @escaping (ClosedRange<Date>?) -> Void) {
        self._selectedDate = selectedDate
        self._selectedDateRange = selectedDateRange
        self.onSave = onSave
        
        // تهيئة مصفوفة الشهور
        var initialMonths: [Date] = []
        let currentDate = Date()
        let startMonth = currentDate.byAddingMonths(-CalendarConstants.initialPageIndex)
        
        for i in 0..<CalendarConstants.monthsToShow {
            if let date = Calendar.current.date(byAdding: .month, value: i, to: startMonth) {
                initialMonths.append(date)
            }
        }
        
        // تعيين القيمة الأولية للمتغير
        _months = State(initialValue: initialMonths)
    }
    
    // MARK: - معالجات التاريخ
    // الحصول على بداية ونهاية الشهر
    private func getMonthRange(for date: Date) -> ClosedRange<Date> {
        let components = calendar.dateComponents([.year, .month], from: date)
        let startOfMonth = calendar.date(from: components)!
        
        var nextMonthComponents = DateComponents()
        nextMonthComponents.month = 1
        nextMonthComponents.day = -1
        let endOfMonth = calendar.date(byAdding: nextMonthComponents, to: startOfMonth)!
        
        // إذا كان الشهر الحالي، نستخدم اليوم الحالي كنهاية
        if calendar.isDate(startOfMonth, equalTo: calendar.startOfDay(for: Date()), toGranularity: .month) {
            return startOfMonth...today
        }
        
        return startOfMonth...endOfMonth
    }
    
    // دالة لتحديد ما إذا كان الشهر المحدد قابل للعرض (الشهور السابقة والشهر الحالي فقط)
    private func isMonthAvailable(_ date: Date) -> Bool {
        let month = calendar.startOfDay(for: date)
        let currentMonth = calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!)
        
        // نتحقق فقط من الشهر، وليس من اليوم
        return calendar.compare(month, to: currentMonth, toGranularity: .month) != .orderedDescending
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {
            // عرض الشهر الحالي وأزرار التنقل
            HStack {
                if let currentMonth = months.indices.contains(pageIndex) ? months[pageIndex] : nil {
                    HStack(spacing: 15) {
                        Button(action: {
                            withAnimation {
                                if pageIndex > 0 {
                                    pageIndex -= 1
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(pageIndex > 0 ? Color.black : Color.gray)
                        }
                        .disabled(pageIndex <= 0)
                        
                        Button(action: {
                            withAnimation {
                                if pageIndex < months.count - 1 {
                                    pageIndex += 1
                                }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(pageIndex < months.count - 1 && isMonthAvailable(months[min(pageIndex + 1, months.count - 1)]) ? Color.black : Color.gray)
                        }
                        .disabled(pageIndex >= months.count - 1 || !isMonthAvailable(months[min(pageIndex + 1, months.count - 1)]))
                    }
                    
                    Spacer()
                    
                    // زر مسح التحديد
                    if tempStartDate != nil || tempEndDate != nil {
                        Button(action: clearSelection) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title3)
                        }
                        .padding(.trailing, 8)
                    }
                    
                    // عنوان الشهر
                    Text(monthYearString(from: currentMonth))
                        .font(.system(size: UIScreen.main.bounds.width < 350 ? 16 : 20, weight: .bold))
                        .foregroundColor(Color.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .frame(height: 40)

            
            // عرض أيام الأسبوع
            HStack {
                ForEach(weekDayNames, id: \.self) { day in
                    Text(day)
                        .font(
                            Font.custom("Bahij TheSansArabic", size: 12)
                                .weight(.bold)
                        )
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.black)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .frame(height: 30)

            // عرض التقويم مع ميزة التمرير الصفحي
            TabView(selection: $pageIndex) {
                ForEach(months.indices, id: \.self) { index in
                    if months.indices.contains(index) {
                        MonthView(
                            month: months[index],
                            tempStartDate: $tempStartDate,
                            tempEndDate: $tempEndDate,
                            today: today,
                            calendar: calendar,
                            isDateSelected: isDateSelected,
                            isDateInRange: isDateInRange,
                            isDateAvailable: isDateAvailable,
                            isDateInFuture: isDateInFuture,
                            handleDateSelection: handleDateSelection
                        )
                        .tag(index)
                    }
                }
                Spacer()
            }
            .frame(height: CalendarConstants.monthGridHeight) // تغيير الارتفاع بناء على نوع العرض
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .padding(.bottom, 0)
            
            // Save button
            SaveButton(action: {
                if let start = tempStartDate {
                    selectedDateRange = start...(tempEndDate ?? start)
                } else if let currentMonth = months.indices.contains(currentPageIndex) ? months[currentPageIndex] : nil {
                    selectedDateRange = getMonthRange(for: currentMonth)
                }
                onSave(selectedDateRange)
            })
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        
        .environment(\.layoutDirection, .rightToLeft)
        .background(Color.white)
        
        // مراقبة التغييرات
        .onChange(of: selectedDateRange) { _ in
            tempStartDate = nil
            tempEndDate = nil
        }
        
        .onChange(of: selectedDate) { _ in
            // عند تغيير التاريخ المحدد، ننتقل إلى الشهر الحالي
            pageIndex = CalendarConstants.initialPageIndex
        }
    }
    
    // MARK: - الوظائف المساعدة
    // مسح التحديد
    private func clearSelection() {
        tempStartDate = nil
        tempEndDate = nil
        selectedDateRange = nil
        onSave(nil)
    }
    
    // التحقق مما إذا كان التاريخ في المستقبل
    private func isDateInFuture(_ date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        return startOfDay > today
    }
    
    // نص الشهر والسنة المعروض
    private func monthYearString(from date: Date) -> String {
        let year = date.FormatterToString("yyyy", "en_US_POSIX")
        let month = date.FormatterToString("MMMM", "en_US_POSIX")
        return "\(month) \(year)"
    }
    
    // التحقق من توفر التاريخ للاختيار
    private func isDateAvailable(_ date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        let todayStartOfDay = calendar.startOfDay(for: today)
        
        return startOfDay <= todayStartOfDay
    }
    
    // التحقق مما إذا كان التاريخ محدداً
    private func isDateSelected(_ date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        return (tempStartDate.map { calendar.isDate($0, inSameDayAs: startOfDay) } ?? false) ||
        (tempEndDate.map { calendar.isDate($0, inSameDayAs: startOfDay) } ?? false)
    }
    
    // التحقق مما إذا كان التاريخ ضمن النطاق المحدد
    private func isDateInRange(_ date: Date) -> Bool {
        guard let start = tempStartDate, let end = tempEndDate else { return false }
        let startOfDay = calendar.startOfDay(for: date)
        return startOfDay >= calendar.startOfDay(for: start) &&
        startOfDay <= calendar.startOfDay(for: end)
    }
    
    // معالجة تحديد التاريخ
    private func handleDateSelection(_ date: Date) {
        guard isDateAvailable(date) && !isDateInFuture(date) else { return }
        
        let startOfDay = calendar.startOfDay(for: date)
        
        if let existingStart = tempStartDate, calendar.isDate(existingStart, inSameDayAs: startOfDay) {
            if tempEndDate == nil {
                tempEndDate = startOfDay
            } else {
                tempStartDate = nil
                tempEndDate = nil
            }
        } else if let existingEnd = tempEndDate, calendar.isDate(existingEnd, inSameDayAs: startOfDay) {
            tempStartDate = nil
            tempEndDate = nil
        } else if tempStartDate == nil {
            tempStartDate = startOfDay
        } else if tempEndDate == nil {
            if startOfDay < tempStartDate! {
                tempEndDate = tempStartDate
                tempStartDate = startOfDay
            } else {
                tempEndDate = startOfDay
            }
        } else {
            tempStartDate = startOfDay
            tempEndDate = nil
        }
    }
}

// MARK: - عرض الشهر
struct MonthView: View {
    let month: Date
    @Binding var tempStartDate: Date?
    @Binding var tempEndDate: Date?
    let today: Date
    let calendar: Calendar
    let isDateSelected: (Date) -> Bool
    let isDateInRange: (Date) -> Bool
    let isDateAvailable: (Date) -> Bool
    let isDateInFuture: (Date) -> Bool
    let handleDateSelection: (Date) -> Void
    
    var body: some View {
        let days = generateDates()
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    let isCurrentMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
                    
                    DayCell(
                        date: date,
                        isSelected: isDateSelected(date),
                        isInRange: isDateInRange(date),
                        isAvailable: isDateAvailable(date) && !isDateInFuture(date),
                        isToday: calendar.isDate(date, inSameDayAs: today),
                        isStartDate: tempStartDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false,
                        isEndDate: tempEndDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false,
                        onTap: { handleDateSelection(date) },
                        isCurrentMonth: isCurrentMonth,
                        indexInRange: days.startIndex
                    )
                } else {
                    Text("")
                        .frame(height: 40)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // إنشاء مصفوفة بتواريخ الشهر
    private func generateDates() -> [Date?] {
        var dates: [Date?] = []
        
        // الحصول على أول يوم في الشهر الحالي
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        
        // الحصول على عدد الأيام في الشهر الحالي
        let range = calendar.range(of: .day, in: .month, for: month)!
        
        // تحديد يوم الأسبوع الأول في الشهر (0 = الأحد، 1 = الإثنين، ... ، 6 = السبت)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        // إضافة أيام الشهر السابق
        if firstWeekday > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: month)!
            let previousMonthDays = calendar.range(of: .day, in: .month, for: previousMonth)!
            let startDay = previousMonthDays.count - firstWeekday + 1
            
            for day in startDay...previousMonthDays.count {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth))!) {
                    dates.append(date)
                }
            }
        }
        
        // إضافة أيام الشهر الحالي
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                dates.append(date)
            }
        }
        
        // إضافة أيام الشهر التالي لملء الصف الأخير
        let totalDays = dates.count
        let remainingDays = (7 - (totalDays % 7)) % 7
        
        if remainingDays > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: month)!
            for day in 1...remainingDays {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!) {
                    dates.append(date)
                }
            }
        }
        
        return dates
    }
    
}

// MARK: - خلية اليوم
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isInRange: Bool
    let isAvailable: Bool
    let isToday: Bool
    let isStartDate: Bool
    let isEndDate: Bool
    let onTap: () -> Void
    let isCurrentMonth: Bool
    
    private let calendar = Calendar.current
    @State private var animationAmount: CGFloat = 1
    
    let indexInRange: Int?
    @State private var appearAnimation = false
    
    var body: some View {
        Button(action: onTap) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: .heavy))
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            ZStack {
                                Rectangle()
                                    .fill(CalendarConstants.backgroundColor)
                                    .cornerRadius(isStartDate ? 8 : 0, corners: [.topRight, .bottomRight])
                                    .cornerRadius(isEndDate ? 8 : 0, corners: [.topLeft, .bottomLeft])
                                
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 32, height: 32)
                                    .scaleEffect(animationAmount)
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever(autoreverses: true),
                                        value: animationAmount
                                    )
                            }
                        } else if isInRange {
                            Rectangle()
                                                .fill(CalendarConstants.backgroundColor)
                                                .opacity(appearAnimation ? 1 : 0)
                                                .scaleEffect(appearAnimation ? 1 : 0.9)
                                                .animation(
                                                    Animation.spring(response: 0.5, dampingFraction: 0.7)
                                                        .delay(Double(indexInRange ?? 0) * 0.1),
                                                    value: appearAnimation
                                                )
                                                .onAppear {
                                                    appearAnimation = true
                                                }
                        } else if isToday {
                            Rectangle()
                                .fill(CalendarConstants.backgroundColor)
                                .cornerRadius(8, corners: [.topRight, .bottomRight, .topLeft, .bottomLeft])
                                .padding(.horizontal, 4)
                        }
                    }
                )
                .foregroundColor(foregroundColor)
        }
        .disabled(!isAvailable)
        .onChange(of: isSelected) { newValue in
            if newValue {
                animationAmount = 1.1
            } else {
                animationAmount = 1
            }
        }
    }
    
    private var foregroundColor: Color {
            if !isCurrentMonth {
                return .gray.opacity(0.4)
            }
            if !isAvailable && !isToday {
                return .gray.opacity(0.5)
            }
            if isSelected {
                return .white
            }
            if isToday {
                return .black
            }
            return .primary
        }
    
}


struct SaveButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Save")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .cornerRadius(12)
                .shadow(color: Color.purple.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}
