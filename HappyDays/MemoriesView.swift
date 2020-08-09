//
//  MemoriesView.swift
//  HappyDays
//
//  Created by Philipp on 08.08.20.
//

import SwiftUI

struct MemoriesView: View {

    @StateObject private var viewModel = MemoriesViewModel()

    @State private var addPhoto: Bool = false
    @State private var selectedPhoto: UIImage?

    @State private var isSearching: Bool = false
    @State private var searchText: String = ""

    var body: some View {
        ScrollView {
            Section {
                SearchField(searchText: $searchText, isEditing: $isSearching)
                    .padding()
            }
            Section {
                LazyVGrid(columns: [GridItem(.fixed(200))],
                          alignment: .center,
                          spacing: 20, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.memories, id: \.baseUrl) { memory in
                        MemoryCell(memory: memory)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color("GridViewBackground"))
        .navigationBarTitle("Happy Days", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: { addPhoto.toggle() }, label: {
            Image(systemName: "plus")
                .imageScale(.large)
                .padding(4)
        }))
        .sheet(isPresented: $addPhoto, onDismiss: {
            if let image = selectedPhoto {
                viewModel.saveNewMemory(image: image)
                viewModel.loadMemories()
            }
        }, content: {
            ImagePicker(image: $selectedPhoto)
        })
        .onAppear() {
            viewModel.loadMemories()
        }
    }
}

struct MemoryCell: View {
    let memory: Memory

    var body: some View {
        Image(uiImage: UIImage(contentsOfFile: memory.thumbnailURL.path)!)
            .resizable()
            .scaledToFill()
        .frame(width: 200, height: 200, alignment: .center)
        .clipped()
    }
}


struct MemoriesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MemoriesView()
        }
    }
}
