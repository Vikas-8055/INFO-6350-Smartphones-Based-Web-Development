import Foundation

struct User {
    let name: String
    let role: String
    
    func userInfo() -> String {
        return "\(name) (\(role))"
    }
}

struct Task {
    let title: String
    let description: String
    let priority: String
    var state: TaskState
    var assignee: User?
    let creationDate: Date
    
    func taskDetails() {
        let assigneeInfo = assignee?.userInfo() ?? "Unassigned"
        print("""
        Title: \(title)
        Description: \(description)
        Priority: \(priority)
        State: \(state.rawValue)
        Assignee: \(assigneeInfo)
        Creation Date: \(creationDate.formattedCreationDate())
        """)
    }
}

class AgileBoard {
    let boardName: String
    var tasks: [Task]
    
    init(boardName: String) {
        self.boardName = boardName
        self.tasks = []
    }
    
  
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    

    func displayBoard() {
        print("Board Name: \(boardName)")
        for task in tasks {
            task.taskDetails()
            print("------")
        }
    }
}

class Sprint: AgileBoard {
    let durationDays: Int
    
    init(boardName: String, durationDays: Int) {
        self.durationDays = durationDays
        super.init(boardName: boardName)
    }
    
 
    func sprintDetails() {
        print("""
        Sprint Name: \(boardName)
        Duration: \(durationDays) days
        Total Tasks: \(tasks.count)
        """)
    }
}

protocol TaskManagement {
    mutating func assign(to user: User)
    mutating func move(to newState: TaskState) throws
}

extension Task: TaskManagement {
    mutating func assign(to user: User) {
        self.assignee = user
    }
    
    
    mutating func move(to newState: TaskState) throws {
     
        let validTransitions: [TaskState: [TaskState]] = [
            .toDo: [.inProgress],
            .inProgress: [.codeReview],
            .codeReview: [.done, .inProgress],
            .done: []
        ]
        
    
        if let validStates = validTransitions[state], validStates.contains(newState) {
            state = newState
        } else {
            throw TaskError.invalidStateTransition
        }
    }
}

extension Date {
    func formattedCreationDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension TaskState {
    var description: String {
        return self.rawValue
    }
}

extension String {
    func standardPriority() -> String {
        switch self.lowercased() {
        case "h": return "High"
        case "m": return "Medium"
        case "l": return "Low"
        default: return "Unknown"
        }
    }
}

enum TaskState: String {
    case toDo = "To Do"
    case inProgress = "In Progress"
    case codeReview = "Code Review"
    case done = "Done"
}

enum TaskError: Error {
    case taskNotFound
    case invalidStateTransition
}

extension AgileBoard {
    func moveTask(taskTitle: String, to newState: TaskState) throws {
        guard let taskIndex = tasks.firstIndex(where: { $0.title == taskTitle }) else {
            throw TaskError.taskNotFound
        }
        
        var task = tasks[taskIndex]
        try task.move(to: newState)
        tasks[taskIndex] = task
        print("Task '\(taskTitle)' moved to \(newState.description).")
    }
}

let user1 = User(name: "Abhishek", role: "Developer")
let user2 = User(name: "Nikhil", role: "Tester")
let user3 = User(name: "Shankar", role: "Project Manager")

var task1 = Task(title: "Implement Payment Gateway", description: "Integrate a secure payment gateway for processing transactions.", priority: "High", state: .toDo, assignee: nil, creationDate: Date())
var task2 = Task(title: "Test Payment Processing", description: "Verify successful transaction processing and error handling.", priority: "Medium", state: .toDo, assignee: nil, creationDate: Date())
var task3 = Task(title: "Finalize Payment Feature", description: "Review implementation and testing results before deployment.", priority: "Low", state: .toDo, assignee: nil, creationDate: Date())

task1.assign(to: user1)
task2.assign(to: user2)
task3.assign(to: user3)

let mainBoard = AgileBoard(boardName: "Main Board")
mainBoard.addTask(task1)
mainBoard.addTask(task2)
mainBoard.addTask(task3)

mainBoard.displayBoard()

let sprint1 = Sprint(boardName: "Sprint 1", durationDays: 14)
sprint1.addTask(task1)
sprint1.addTask(task2)
sprint1.addTask(task3)

sprint1.sprintDetails()

do {
    try mainBoard.moveTask(taskTitle: "Implement Login Feature", to: .inProgress)
    try mainBoard.moveTask(taskTitle: "Implement Login Feature", to: .codeReview)
    try mainBoard.moveTask(taskTitle: "Implement Login Feature", to: .done)
} catch TaskError.taskNotFound {
    print("Error: Task not found.")
} catch TaskError.invalidStateTransition {
    print("Error: Invalid state transition.")
}

print("Formatted Date: \(Date().formattedCreationDate())")
print("Priority 'h' converted: \("h".standardPriority())")
print("Task state description: \(TaskState.toDo.description)")

do {
    try task1.move(to: .done)
} catch TaskError.invalidStateTransition {
    print("Error: Invalid state transition.")
} catch {
    print("Error: \(error)")
}

do {
    try mainBoard.moveTask(taskTitle: "Non-Existent Task", to: .inProgress)
} catch TaskError.taskNotFound {
    print("Error: Task not found.")
} catch {
    print("Error: \(error)")
}
