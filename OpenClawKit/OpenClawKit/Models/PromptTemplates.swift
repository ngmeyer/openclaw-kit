import Foundation

// MARK: - Prompt Templates
// Based on Alex Finn's best practices for OpenClaw

struct PromptTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: PromptCategory
    let prompt: String
    let icon: String
    
    enum PromptCategory: String, CaseIterable {
        case productivity = "Productivity"
        case development = "Development"
        case research = "Research"
        case lifestyle = "Lifestyle"
    }
}

struct PromptTemplates {
    
    static let all: [PromptTemplate] = [
        // MARK: - Productivity
        PromptTemplate(
            name: "Morning Brief",
            description: "Daily morning briefing with weather, tasks, and insights",
            category: .productivity,
            icon: "sunrise.fill",
            prompt: """
            I want you to send me a morning brief every morning at 8am my time. I want this morning brief to include:
            - The local weather for the day
            - A list of trending news about my interests and field
            - Tasks I need to get done today based on my todo list
            - Tasks you think you can do for me today that will be helpful
            - A list of trending stories based on my interests
            - Recommendations to make today super productive
            """
        ),
        
        PromptTemplate(
            name: "Afternoon Research Report",
            description: "Daily research deep-dive on topics relevant to you",
            category: .research,
            icon: "doc.text.magnifyingglass",
            prompt: """
            I want a daily research report sent to me every afternoon. Based on what you know about me, I want you to research and give me a report about:
            - A concept that would improve me
            - Processes that would improve our working relationship
            - Anything else that would be helpful for me
            Examples: deep dives on concepts I'm interested in, new workflows we can implement together to improve productivity.
            """
        ),
        
        // MARK: - Development
        PromptTemplate(
            name: "Proactive Coder",
            description: "AI works overnight building features and improvements",
            category: .development,
            icon: "hammer.fill",
            prompt: """
            I am a 1 person business. I work from the moment I wake up to the moment I go to sleep. I need an employee taking as much off my plate and being as proactive as possible.
            
            Please take everything you know about me and just do work you think would make my life easier or improve my business. I want to wake up every morning and be like "wow, you got a lot done while I was sleeping."
            
            Don't be afraid to monitor my business and build things that would help improve our workflow. Just create PRs for me to review, don't push anything live. I'll test and commit.
            
            Every night when I go to bed, build something cool I can test. Schedule time to work every night at 11pm.
            """
        ),
        
        PromptTemplate(
            name: "Second Brain",
            description: "Build a personal knowledge management system",
            category: .development,
            icon: "brain.head.profile",
            prompt: """
            I want you to build me a second brain. This should be an app that shows a list of documents you create as we work together in a nice document viewer that feels like a mix of Obsidian and Linear.
            
            Create a folder where all the documents are viewable in this second brain. Update your memories so that as we talk every day, you create documents that explore the more important concepts we discuss.
            
            You should also create daily journal entries that record from a high level all our daily discussions.
            """
        ),
        
        // MARK: - Research
        PromptTemplate(
            name: "Competitor Analysis",
            description: "Monitor competitors and identify trending content",
            category: .research,
            icon: "chart.line.uptrend.xyaxis",
            prompt: """
            I want you to scan YouTube and Twitter overnight, identify outlier content from my competitors that is performing unusually well, and include your findings in a morning briefing.
            
            Look for:
            - Videos/posts with unusually high engagement
            - New trends in my industry
            - Gaps in the market I could fill
            - Content ideas I could adapt
            """
        ),
        
        PromptTemplate(
            name: "Interview Your Bot",
            description: "Discover capabilities you didn't know about",
            category: .productivity,
            icon: "questionmark.bubble.fill",
            prompt: """
            Based on my role and what you know about me, what are 10 things you can do to make my life easier that I might not have thought of?
            
            For each suggestion:
            1. Explain what you can do
            2. How it would help me
            3. What you need from me to get started
            
            Be creative and think outside the box. What are the "unknown unknowns" I should know about?
            """
        ),
        
        // MARK: - Lifestyle
        PromptTemplate(
            name: "Smart Home Integration",
            description: "Automate your home environment",
            category: .lifestyle,
            icon: "house.fill",
            prompt: """
            Help me set up smart home automations. I want you to:
            - Check if doors are locked before bed
            - Verify the garage is closed
            - Adjust thermostat based on my schedule
            - Turn off lights when I leave
            
            Note: Only proceed with integrations I explicitly authorize.
            """
        ),
        
        PromptTemplate(
            name: "Proactive Mandate",
            description: "Give your AI permission to take initiative",
            category: .productivity,
            icon: "bolt.fill",
            prompt: """
            I want you to be proactive and take initiative. Don't just wait for my prompts - identify opportunities and act on them.
            
            You have permission to:
            - Research topics relevant to my work
            - Draft responses to routine messages
            - Organize and summarize information
            - Suggest improvements to my workflows
            - Build tools that would help me
            
            Always check with me before taking any external actions (sending emails, making purchases, etc).
            """
        )
    ]
    
    static func templates(for category: PromptTemplate.PromptCategory) -> [PromptTemplate] {
        all.filter { $0.category == category }
    }
}
