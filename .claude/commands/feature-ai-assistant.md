---
description: "Triển khai feature AI Financial Assistant — F3.3 Chat interface + Claude API integration (Premium)"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: AI Financial Assistant

## Feature Spec References
- F3.3: AI Financial Assistant (Chat)

## Đọc Context Trước
1. `CLAUDE.md` — tech stack, code rules, module structure
2. `FinanceApp-Feature-Specification.md` → section 6.1 "F3.3 — AI Financial Assistant (Chat)" + section 9 "AI Architecture — Hybrid Strategy"
3. `docs/DATA-MODEL.md` → Transaction, Category, Account, Budget entities
4. `docs/ARCHITECTURE.md` → Clean Architecture layers, networking
5. `docs/CONVENTIONS.md` → Swift naming, error handling, async/await patterns

## Tasks

### FinanceCore
1. `ChatMessage` model:
   - id: UUID
   - role: ChatRole
   - content: String
   - timestamp: Date
   - metadata: ChatMessageMetadata?

2. `ChatRole` enum:
   - user
   - assistant
   - system

3. `ChatMessageMetadata` model:
   - referencedTransactions: [UUID]? (giao dịch được nhắc tới)
   - referencedCategories: [UUID]?
   - referencedAccounts: [UUID]?
   - suggestedActions: [SuggestedAction]?
   - dataSnapshot: FinancialDataSnapshot? (data dùng để trả lời)

4. `SuggestedAction` enum:
   - viewTransactions(filter: TransactionFilter)
   - viewBudget(categoryId: UUID)
   - viewReport(type: ReportType, dateRange: ClosedRange<Date>)
   - createBudget(categoryId: UUID, suggestedAmount: Decimal)
   - viewCategory(categoryId: UUID)

5. `ChatConversation` model:
   - id: UUID
   - title: String? (auto-generated từ câu hỏi đầu)
   - messages: [ChatMessage]
   - createdAt: Date
   - updatedAt: Date

6. `FinancialDataSnapshot` model (aggregated data gửi lên Cloud AI — KHÔNG gửi raw transactions):
   - totalBalance: Decimal
   - monthlyIncome: Decimal
   - monthlyExpense: Decimal
   - categoryBreakdown: [CategorySummary] (categoryName, amount, percentage)
   - monthlyTrend: [MonthSummary] (month, income, expense) — 6 tháng gần nhất
   - topExpenseCategories: [CategorySummary] — top 5
   - budgetStatus: [BudgetSummary] (categoryName, budgeted, spent, remaining)
   - accountBalances: [AccountSummary] (name, type, balance, currency)
   - savingsGoalProgress: [GoalSummary] (name, target, current, percentage)

7. `CategorySummary`, `MonthSummary`, `BudgetSummary`, `AccountSummary`, `GoalSummary` — lightweight summary structs cho snapshot.

8. `AIChatService` protocol:
   - sendMessage(content: String, context: FinancialDataSnapshot, conversationHistory: [ChatMessage]) async throws -> ChatMessage
   - streamMessage(content: String, context: FinancialDataSnapshot, conversationHistory: [ChatMessage]) -> AsyncThrowingStream<String, Error>

9. `ClaudeAPIChatService` implementation:
   - Base URL: configurable via server config
   - Model: Claude Sonnet (cost-effective cho chat)
   - System prompt: financial assistant persona, tiếng Việt + English
   - Max conversation history: 10 messages (để giảm token cost)
   - Timeout: 30 seconds
   - Privacy: chỉ gửi FinancialDataSnapshot, KHÔNG gửi raw transaction data

10. `BuildFinancialSnapshotUseCase` (protocol + implementation):
    - Aggregate data từ repositories → FinancialDataSnapshot
    - Input: dateRange (mặc định tháng hiện tại + 6 tháng lịch sử)
    - Logic: tính tổng income/expense, group by category, budget status, goal progress
    - Strip PII: không include note, location, receipt — chỉ aggregated numbers

11. `SendChatMessageUseCase` (protocol + implementation):
    - Input: userMessage: String, conversationId: UUID?
    - Output: ChatMessage (assistant response)
    - Logic: build snapshot → append to conversation → call AIChatService → save response
    - Check premium status trước khi gọi
    - Check monthly question limit (Premium: 20/tháng, Premium+: không giới hạn)

12. `ChatLimitService` (protocol + implementation):
    - checkCanAsk() -> Bool
    - incrementQuestionCount()
    - remainingQuestions() -> Int
    - resetDate() -> Date
    - Tier limits: Premium = 20/tháng, Premium+ = unlimited, Free = 0

13. `AIChatError` enum:
    - notPremium
    - questionLimitReached(remaining: Int)
    - networkError(underlying: Error)
    - apiError(statusCode: Int, message: String)
    - responseParsingFailed
    - timeout
    - serviceUnavailable

14. Prompt template constants:
    - `systemPrompt`: "Bạn là trợ lý tài chính cá nhân thông minh. Trả lời bằng tiếng Việt hoặc English tùy ngôn ngữ người dùng. Dựa trên dữ liệu tài chính được cung cấp. KHÔNG đưa lời khuyên đầu tư cụ thể. Luôn có disclaimer khi nói về tài chính."
    - Ví dụ câu hỏi mẫu cho onboarding

### FinanceData
15. `ChatConversationEntity` @Model:
    - id: UUID, title: String?, createdAt: Date, updatedAt: Date
    - Index on: (updatedAt DESC)

16. `ChatMessageEntity` @Model:
    - id: UUID, role: String, content: String, timestamp: Date
    - conversationId: UUID
    - metadataJSON: String? (encoded ChatMessageMetadata)
    - Index on: (conversationId, timestamp)

17. `ChatRepositoryImpl`:
    - saveConversation(ChatConversation)
    - fetchConversations(limit: Int, offset: Int) -> [ChatConversation]
    - fetchMessages(conversationId: UUID) -> [ChatMessage]
    - deleteConversation(id: UUID)
    - deleteAllConversations()
    - countQuestionsThisMonth() -> Int

18. `APIKeyStorage` — lưu Claude API key an toàn trong Keychain:
    - save(apiKey: String)
    - retrieve() -> String?
    - delete()

### FinanceUI
19. `ChatBubble` — message bubble component:
    - User message: trailing aligned, accent color background
    - Assistant message: leading aligned, secondary background
    - Support markdown rendering trong assistant messages
    - Timestamp nhỏ bên dưới

20. `ChatInputBar` — thanh nhập tin nhắn:
    - TextField multiline (expandable)
    - Send button (disabled khi empty)
    - Suggested questions chips (khi conversation mới)
    - Character count / remaining questions indicator

21. `SuggestedQuestionChip` — chip gợi ý câu hỏi:
    - "Tháng này tôi chi bao nhiêu?"
    - "Nên cắt giảm ở đâu?"
    - "So sánh chi tiêu với tháng trước"
    - "Tôi có đủ tiền mua iPhone không?"

22. `FinancialActionCard` — card cho suggested actions trong response:
    - Icon + title + description
    - Tap → navigate đến section tương ứng (transactions, budget, report)

23. `ChatLimitBanner` — banner giới hạn câu hỏi:
    - "Còn 15/20 câu hỏi tháng này"
    - Premium+ badge nếu unlimited
    - Upgrade button khi hết lượt

24. `TypingIndicator` — animation dots khi AI đang trả lời

### iOS
25. `AIChatView` — main chat screen:
    - NavigationStack with title "Trợ lý AI"
    - ScrollViewReader auto-scroll to bottom on new message
    - ChatBubble list
    - ChatInputBar pinned at bottom
    - Empty state: giới thiệu + suggested questions
    - Loading state: TypingIndicator
    - Error state: retry button

26. `AIChatViewModel` (@Observable):
    - Dependencies: SendChatMessageUseCase, ChatLimitService, ChatRepository
    - State: messages: [ChatMessage], isLoading: Bool, error: AIChatError?
    - currentConversation: ChatConversation?
    - remainingQuestions: Int
    - suggestedQuestions: [String]
    - Methods: sendMessage(String), startNewConversation(), loadConversation(UUID), deleteConversation()
    - Handle streaming response: update last message content progressively

27. `ChatHistoryView` — danh sách conversations cũ:
    - List conversations sorted by updatedAt DESC
    - Title + last message preview + date
    - Swipe-to-delete
    - Tap → load conversation

28. `ChatSettingsView`:
    - Language preference (Việt / English / Auto)
    - Clear all conversations
    - Privacy info: "Chỉ dữ liệu tổng hợp được gửi, không gửi giao dịch cụ thể"
    - API usage stats

29. Navigation integration:
    - Tab bar item: "Trợ lý" với AI icon (SF Symbol: bubble.left.and.text.bubble.right)
    - Badge count cho unread insights (optional)
    - Quick action: 3D Touch / long press app icon → "Hỏi AI"
    - Spotlight integration: search "AI assistant" / "Trợ lý tài chính"

### macOS
30. `AIChatMacView`:
    - Sidebar panel hoặc separate window
    - Keyboard shortcut: ⌘⇧A → open AI chat
    - Wider layout: chat history sidebar + conversation main area
    - Support copy message text (⌘C)
    - Support select text in assistant messages

31. `ChatHistoryMacSidebar`:
    - Sidebar list conversations
    - Search conversations
    - Right-click → delete, rename

32. Keyboard shortcuts:
    - ⌘⇧A: Open AI Assistant
    - ⌘N: New conversation (khi đang trong chat)
    - Enter: Send message
    - ⇧Enter: New line trong input
    - Esc: Close chat panel

### Tests
33. `BuildFinancialSnapshotUseCaseTests`:
    - Snapshot includes correct totals (income, expense, balance)
    - Category breakdown percentages sum to 100%
    - Monthly trend covers 6 months
    - Empty data → valid snapshot with zeros
    - Snapshot does NOT contain raw transaction notes or PII

34. `SendChatMessageUseCaseTests`:
    - Successful send → assistant response saved to conversation
    - Not premium → error notPremium
    - Question limit reached → error questionLimitReached
    - Network error → proper error propagation
    - Conversation history passed correctly (max 10 messages)

35. `ClaudeAPIChatServiceTests`:
    - Request format correct (system prompt, user message, context)
    - Response parsed correctly
    - Timeout handling (> 30s)
    - HTTP error codes handled (401, 429 rate limit, 500)
    - Streaming response chunks assembled correctly

36. `ChatLimitServiceTests`:
    - Premium: 20 questions/month limit enforced
    - Premium+: unlimited
    - Free: always returns false
    - Count resets at month boundary
    - Concurrent access safe

37. `AIChatViewModelTests`:
    - Send message → appears in list → loading → response appears
    - New conversation flow
    - Load existing conversation
    - Error display and retry
    - Suggested questions shown for empty conversation
    - Remaining questions count updates after each send
