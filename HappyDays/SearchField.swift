//
//  SearchField.swift
//  HappyDays
//
//  Created by Philipp on 08.08.20.
//

import SwiftUI

struct SearchField: View {
    @Binding public var searchText : String

    @Binding public var isEditing : Bool

    let onCommit: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
                    .padding(.trailing, 4)
                    .accessibility(identifier: "magnifyingGlass")
                    .accessibility(hidden: true)

                TextField("Search", text: $searchText, onCommit: onCommit)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 7)
                    .disableAutocorrection(true)
                    .accessibility(identifier: "searchText")
                    .accessibility(label: Text("Search"))
                    .accessibility(addTraits: .isSearchField)
                    .onTapGesture {
                        self.isEditing = true
                    }
                    .animation(.easeInOut)

                if isEditing && !searchText.isEmpty {
                    Button(action: { withAnimation { self.searchText = "" }}) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                    }
                    .hoverEffect()
                    .accessibility(label: Text("Clear"))
                    .accessibility(identifier: "clearButton")
                    //.frame(maxWidth: .infinity, alignment: .trailing)
                    .animation(Animation.easeInOut)
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)

            if isEditing {
                Button(action: {
                    self.isEditing = false
                    self.searchText = ""
                    UIApplication.shared.endEditing()
                }) {
                    Text("Cancel")
                        .padding(4)
                }
                .hoverEffect()
                .accessibility(identifier: "cancelButton")
                .buttonStyle(BorderlessButtonStyle())
                .padding(.leading, 8)
                .transition(.move(edge: .trailing))
                .animation(.easeInOut)
            }

        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .transition(.move(edge: .trailing))
        .animation(.easeInOut)
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .contain)
        .accessibility(identifier: "searchBar")
    }
}


struct SearchField_Previews: PreviewProvider {
    struct Preview_Helper: View {
        @State var query: String
        @State var edit: Bool

        init(query: String, edit: Bool) {
            _query = State<String>(initialValue: query)
            _edit = State<Bool>(initialValue: edit)
        }

        var body: some View {
            VStack {
                SearchField(searchText: $query,
                            isEditing: $edit,
                            onCommit: {})
                    .padding()

                Button(action: {
                    self.edit.toggle()
                    if !self.edit {
                        UIApplication.shared.endEditing()
                    }
                }) {
                    Text("Toggle Edit")
                }
            }
        }
    }


    static var previews: some View {
        Group {
            VStack {
                Preview_Helper(query: "", edit: false)
                    .previewLayout(.fixed(width: 400, height: 120))
                Divider()
                Preview_Helper(query: "Foobar", edit: false)
                    .previewLayout(.fixed(width: 400, height: 120))
                Divider()
                Preview_Helper(query: "Foobar", edit: true)
                    .previewLayout(.fixed(width: 400, height: 120))
            }
            VStack {
                Preview_Helper(query: "", edit: false)
                    .previewLayout(.fixed(width: 400, height: 120))
                Divider()
                Preview_Helper(query: "Foobar", edit: false)
                    .previewLayout(.fixed(width: 400, height: 120))
                Divider()
                Preview_Helper(query: "Foobar", edit: true)
                    .previewLayout(.fixed(width: 400, height: 120))
            }
            .preferredColorScheme(.dark)
        }

    }
}
