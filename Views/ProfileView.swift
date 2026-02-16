import SwiftUI
import SwiftData

@available(iOS 17.0, *)
@available(iOS 17.0, *)
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @State private var favoriteTopics: String = ""
    @State private var improvementAreas: [String] = []
    @State private var comfortFactors: [String] = []
    @State private var conversationalFeeling: String = ""
    @State private var afterConversationFeeling: String = ""
    @State private var isEditing: Bool = false
    
    var userProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.primary.opacity(0.05).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // User Avatar / Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Theme.primary, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Theme.primary.opacity(0.2), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Communication Profile")
                                    .font(.title2.bold())
                                Text("Tailoring analysis to your needs")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Fields
                        VStack(spacing: 24) {
                            ProfileEditSection(title: "What do you love talking about?", content: $favoriteTopics, icon: "heart.fill", isEditing: isEditing)
                            
                            ProfileMultiSelectionSection(
                                title: "Improvement Goals", 
                                options: ["Waiting my turn", "Speaking at the right volume", "Not talking for too long", "Understanding when others want to speak", "I’m not sure yet"],
                                selections: $improvementAreas, 
                                icon: "target", 
                                isEditing: isEditing
                            )
                            
                            ProfileMultiSelectionSection(
                                title: "Comfort Factors", 
                                options: ["Talking about my favorite topics", "Clear back-and-forth", "Quiet environments", "One-on-one conversations"],
                                selections: $comfortFactors, 
                                icon: "leaf.fill", 
                                isEditing: isEditing
                            )
                            
                            ProfileSingleSelectionSection(
                                title: "General Feeling", 
                                options: ["Relaxed", "Excited", "Nervous", "Unsure what to say"],
                                selection: $conversationalFeeling, 
                                icon: "brain.head.profile", 
                                isEditing: isEditing
                            )
                            
                            ProfileEditSection(title: "After-Conversation Feeling", content: $afterConversationFeeling, icon: "clock.fill", isEditing: isEditing)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: toggleEdit) {
                        Text(isEditing ? "Done" : "Edit")
                            .fontWeight(.bold)
                    }
                }
            }
            .onAppear(perform: loadData)
        }
    }
    
    private func loadData() {
        if let profile = userProfile {
            favoriteTopics = profile.favoriteTopics
            improvementAreas = profile.improvementAreas
            comfortFactors = profile.comfortFactors
            conversationalFeeling = profile.conversationalFeeling
            afterConversationFeeling = profile.afterConversationFeeling
        }
    }
    
    private func toggleEdit() {
        if isEditing {
            saveData()
        }
        withAnimation(.spring()) {
            isEditing.toggle()
        }
    }
    
    private func saveData() {
        if let profile = userProfile {
            profile.favoriteTopics = favoriteTopics
            profile.improvementAreas = improvementAreas
            profile.comfortFactors = comfortFactors
            profile.conversationalFeeling = conversationalFeeling
            profile.afterConversationFeeling = afterConversationFeeling
        }
    }
}

struct ProfileEditSection: View {
    let title: String
    @Binding var content: String
    let icon: String
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Theme.primary)
            
            if isEditing {
                TextField("Enter...", text: $content, axis: .vertical)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.primary.opacity(0.1), lineWidth: 1)
                    )
            } else {
                Text(content.isEmpty ? "Not set" : content)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
    }
}

struct ProfileMultiSelectionSection: View {
    let title: String
    let options: [String]
    @Binding var selections: [String]
    let icon: String
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Theme.primary)
            
            if isEditing {
                FlowLayout(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = selections.contains(option)
                        Button(action: {
                            if isSelected {
                                selections.removeAll { $0 == option }
                            } else {
                                selections.append(option)
                            }
                        }) {
                            Text(option)
                                .font(.caption.weight(isSelected ? .semibold : .regular))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? Theme.primary.opacity(0.1) : Color(.systemGray6))
                                .foregroundColor(isSelected ? Theme.primary : .primary)
                                .cornerRadius(15)
                        }
                    }
                }
            } else {
                if selections.isEmpty {
                    Text("Not set")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(selections, id: \.self) { selection in
                            Text(selection)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.primary.opacity(0.05))
                                .foregroundColor(Theme.primary)
                                .cornerRadius(15)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct ProfileSingleSelectionSection: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    let icon: String
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Theme.primary)
            
            if isEditing {
                FlowLayout(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = selection == option
                        Button(action: {
                            selection = option
                        }) {
                            Text(option)
                                .font(.caption.weight(isSelected ? .semibold : .regular))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? Theme.primary.opacity(0.1) : Color(.systemGray6))
                                .foregroundColor(isSelected ? Theme.primary : .primary)
                                .cornerRadius(15)
                        }
                    }
                }
            } else {
                Text(selection.isEmpty ? "Not set" : selection)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
    }
}
