//
//  CalendarDemoView.swift
//  Wafid
//
//  Created by almedadsoft on 09/04/2025.
//


import SwiftUI

// شاشة الاستخدام للتقويم المحسن مع ميزة التمرير
struct CalendarDemoView: View {
    @State private var selectedDate: Bool? = nil
    @State private var selectedDateRange: ClosedRange<Date>? = nil
    @State private var formattedRange: String = "No range specified"
    
    var body: some View {
        VStack {
            // عرض النطاق المحدد
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 50)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                Text("Specific range : \(formattedRange)")
                    .font(Font.system(size: 14,weight: .medium))
                    .foregroundColor(.white)
                    .padding()
            }
            .padding(.top ,30)
            .padding(.horizontal)
            
            // التقويم المخصص مع ميزة التمرير
            CustomCalendarView(
                selectedDate: $selectedDate,
                selectedDateRange: $selectedDateRange,
                onSave: saveSelectedRange
            )
            
            // معلومات إضافية حول استخدام التقويم
            VStack(alignment: .leading, spacing: 5) {
                Text("Instructions for use :")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 10, height: 10)
                    Text("Click once on a date to select a start date or twice to select the same day .")
                        .font(.subheadline)
                }.frame(height: 60)
                
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 10, height: 10)
                    Text("Click on another date to specify the end of the range .")
                        .font(.subheadline)
                }.frame(height: 60)
                
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 10, height: 10)
                    Text("Click the Save button to confirm the selected range .")
                        .font(.subheadline)
                }.frame(height: 60)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            Spacer()
        }
        .environment(\.layoutDirection, .leftToRight)
        .font(Font.custom("Bahij TheSansArabic", size: 16))
    }
    
    // معالجة حفظ النطاق المحدد
    func saveSelectedRange(_ range: ClosedRange<Date>?) {
        if let dateRange = range {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            let startString = formatter.string(from: dateRange.lowerBound)
            let endString = formatter.string(from: dateRange.upperBound)
            
            formattedRange = "\(startString) - \(endString)"
        } else {
            formattedRange = "No range specified"
        }
    }
}
