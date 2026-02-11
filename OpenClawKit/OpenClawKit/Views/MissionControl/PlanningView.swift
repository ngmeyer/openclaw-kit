import SwiftUI

/// Planning Q&A workflow view
struct PlanningView: View {
    let task: MissionTask
    @ObservedObject var viewModel: MissionControlViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var currentAnswer = ""
    
    private var currentIndex: Int {
        viewModel.planningQuestions.firstIndex { $0.question == viewModel.currentQuestion } ?? 0
    }
    
    private var progress: Double {
        let answered = viewModel.planningQuestions.filter { $0.isAnswered }.count
        return Double(answered) / Double(viewModel.planningQuestions.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            if viewModel.isPlanningComplete {
                completionView
            } else {
                // Planning Q&A
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress
                        progressSection
                        
                        // Current question
                        currentQuestionSection
                        
                        // Previous answers
                        if currentIndex > 0 {
                            previousAnswersSection
                        }
                    }
                    .padding(24)
                }
                
                Divider()
                
                // Answer input
                answerInputSection
            }
        }
        .frame(width: 600, height: 650)
        .background(Color(hex: "#0A0A0F"))
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Planning: \(task.title)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Help us understand your task requirements")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Question \(currentIndex + 1) of \(viewModel.planningQuestions.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(Color(hex: "#3B82F6"))
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
    
    // MARK: - Current Question Section
    
    private var currentQuestionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                Text("AI Question")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.purple)
            }
            
            Text(viewModel.currentQuestion)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .lineSpacing(6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Previous Answers Section
    
    private var previousAnswersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Previous Answers")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
            
            ForEach(Array(viewModel.planningQuestions.prefix(currentIndex).enumerated()), id: \.element.id) { index, qa in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Q\(index + 1):")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text(qa.question)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Text(qa.answer)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                }
            }
        }
    }
    
    // MARK: - Answer Input Section
    
    private var answerInputSection: some View {
        VStack(spacing: 12) {
            TextEditor(text: $currentAnswer)
                .frame(height: 100)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
                .font(.system(size: 14))
            
            HStack {
                Button("Skip") {
                    currentAnswer = "Skipped"
                    submitAnswer()
                }
                .buttonStyle(.plain)
                .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: submitAnswer) {
                    HStack(spacing: 6) {
                        Text(isLastQuestion ? "Complete Planning" : "Next Question")
                        Image(systemName: isLastQuestion ? "checkmark.circle.fill" : "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(currentAnswer.isEmpty ? Color.gray : Color(hex: "#3B82F6"))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(currentAnswer.isEmpty)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)
            
            Text("Planning Complete!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your task has been planned and is ready for agent assignment.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("View Task")
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#3B82F6"))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
    }
    
    // MARK: - Computed Properties
    
    private var isLastQuestion: Bool {
        currentIndex == viewModel.planningQuestions.count - 1
    }
    
    // MARK: - Actions
    
    private func submitAnswer() {
        viewModel.answerPlanningQuestion(currentAnswer)
        currentAnswer = ""
    }
}

#Preview {
    let viewModel = MissionControlViewModel()
    viewModel.planningTask = MissionTask(
        title: "Research Coffee Machines",
        description: "Find the best coffee machines under $200"
    )
    viewModel.currentQuestion = "What is the primary goal of this task?"
    viewModel.planningQuestions = [
        QAPair(question: "What is the primary goal of this task?", answer: ""),
        QAPair(question: "Who is the target audience?", answer: ""),
        QAPair(question: "What are the key requirements?", answer: "")
    ]
    
    return PlanningView(task: viewModel.planningTask!, viewModel: viewModel)
}
