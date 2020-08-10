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

    var body: some View {
        ScrollView {
            Section {
                SearchField(searchText: $viewModel.searchText, isEditing: $viewModel.isSearching,
                            onCommit: {
                                viewModel.filterMemories(text: viewModel.searchText)
                            })
                    .padding()
            }
            Section {
                LazyVGrid(columns: [GridItem(.fixed(200))],
                          alignment: .center,
                          spacing: 20, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.filteredMemories, id: \.baseUrl) { memory in
                        MemoryCell(memory: memory, isRecording: viewModel.isRecording(memory))
                            .onTapGesture() {
                                viewModel.playAudio(for: memory)
                            }
                            .gesture(
                                LongPressGesture(minimumDuration: 0.25, maximumDistance: 0)
                                    .onEnded({ x in
                                        viewModel.record(memory: memory)
                                    })
                                    .sequenced(before: DragGesture(minimumDistance: 0)
                                                .onEnded({ x in
                                                    viewModel.finishRecording(success: true)
                                                })
                                    )
                            )
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(viewModel.isRecording ? Color.red : Color("GridViewBackground"))
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
    let isRecording: Bool

    var body: some View {
        Image(uiImage: UIImage(contentsOfFile: memory.thumbnailURL.path) ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: 200, height: 200, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3))
                    .foregroundColor(isRecording ? Color.white : Color.clear)
            )
    }
}


struct MemoriesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MemoriesView()
        }
    }
}
