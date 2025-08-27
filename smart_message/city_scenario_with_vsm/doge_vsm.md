# DOGE VSM Documentation

## Department of Government Efficiency - Vector Symbolic Memory Implementation

The DOGE VSM system is an AI-powered government efficiency analysis platform built using the Vector Symbolic Memory (VSM) architecture. It analyzes city department configurations and generates intelligent consolidation recommendations to reduce waste, eliminate redundancies, and optimize resource allocation.

## Architecture Overview

The DOGE VSM system implements the complete VSM paradigm with five core components:

1. **Identity System** - Defines purpose and invariants
2. **Intelligence System** - AI-powered analysis and decision making
3. **Operations System** - Five specialized tools for data processing
4. **Governance System** - Quality control and policy enforcement
5. **Coordination System** - Workflow orchestration and message handling

## System Architecture Diagram

```mermaid
graph TB
    subgraph "DOGE VSM System"
        CLI[CLI Interface<br/>doge_vsm.rb] --> Base[Base Controller<br/>doge_vsm/base.rb]
        Base --> VSM[VSM Capsule Builder]
        
        subgraph "VSM Architecture"
            Identity[Identity System<br/>Core Purpose & Invariants]
            Intelligence[Intelligence System<br/>AI Analysis Engine]
            Operations[Operations System<br/>5 Specialized Tools]
            Governance[Governance System<br/>Quality Control]
            Coordination[Coordination System<br/>Workflow Management]
        end
        
        VSM --> Identity
        VSM --> Intelligence
        VSM --> Operations
        VSM --> Governance
        VSM --> Coordination
        
        subgraph "Operations Tools"
            LoadTool[LoadDepartmentsTool<br/>YAML Parser]
            RecTool[RecommendationGeneratorTool<br/>Analysis Engine]
            ConsTool[CreateConsolidatedDepartmentsTool<br/>File Generator]
            ValidTool[TemplateValidationTool<br/>Structure Validator]
            GenTool[DepartmentTemplateGeneratorTool<br/>Template Generator]
        end
        
        Operations --> LoadTool
        Operations --> RecTool
        Operations --> ConsTool
        Operations --> ValidTool
        Operations --> GenTool
    end
    
    subgraph "External Systems"
        YAML[Department YAML Files<br/>*_department.yml]
        LLM[AI Provider<br/>OpenAI/Ollama/etc]
        Files[Output Files<br/>.doged archives<br/>Consolidated YAMLs]
    end
    
    LoadTool --> YAML
    Intelligence --> LLM
    ConsTool --> Files
    
    subgraph "Configuration Files"
        Template[generic_department_sample.yml<br/>Department Structure Template]
        ConsolidationTemplate[consolidated_department_sample.yml<br/>AI Format Specification]
    end
    
    Intelligence --> ConsolidationTemplate
    ValidTool --> Template
    GenTool --> Template
```

## Data Flow Diagram

```mermaid
flowchart TD
    Start([System Start]) --> Init[Initialize VSM Capsule]
    Init --> Session[Generate Session ID]
    Session --> Request[Create Analysis Request]
    Request --> EmitMsg[Emit User Message to VSM Bus]
    
    EmitMsg --> Intelligence{Intelligence System<br/>Processes Request}
    Intelligence --> LoadDepts[Call: load_departments]
    
    LoadDepts --> ParseYAML[Parse YAML Files<br/>Extract Metadata]
    ParseYAML --> ExtractKeywords[Extract Keywords<br/>& Capabilities]
    ExtractKeywords --> ValidateStructure[Validate Against Template]
    ValidateStructure --> DeptData[Department Data<br/>Collection]
    
    DeptData --> AIAnalysis[AI Analyzes<br/>Similarities & Overlaps]
    AIAnalysis --> GenRecs[Call: generate_recommendations]
    
    GenRecs --> ScoreSimilarity[Calculate Similarity Scores]
    ScoreSimilarity --> EstimateSavings[Estimate Cost Savings]
    EstimateSavings --> CreateRecs[Generate Recommendations]
    CreateRecs --> RecData[Recommendations Data]
    
    RecData --> CreateCons[Call: create_consolidated_departments]
    CreateCons --> ValidateFormat{Validate Input Format<br/>Against Sample}
    ValidateFormat -->|Valid| ProcessCons[Process Consolidations]
    ValidateFormat -->|Invalid| Error[Return Error]
    
    ProcessCons --> FindFiles[Find Department Files<br/>by snake_case names]
    FindFiles --> MergeDepts[Merge Department<br/>Configurations]
    MergeDepts --> GenerateYAML[Generate Consolidated<br/>YAML Files]
    GenerateYAML --> ArchiveOld[Archive Original Files<br/>with .doged suffix]
    ArchiveOld --> Success[Return Success Result]
    
    Success --> DisplayResults[Display Results<br/>to User]
    Error --> DisplayResults
    DisplayResults --> End([End])
    
    subgraph "Governance Layer"
        PolicyCheck[Policy Validation]
        QualityControl[Quality Control]
        NameSanitization[Name Sanitization]
    end
    
    RecData --> PolicyCheck
    PolicyCheck --> QualityControl
    QualityControl --> NameSanitization
    NameSanitization --> CreateCons
```

## Control Flow Diagram

```mermaid
flowchart TD
    UserStart([User Executes<br/>ruby doge_vsm.rb]) --> CLIInit[CLI: Initialize Base Controller]
    CLIInit --> LogSetup[Setup Logging & Status Line]
    LogSetup --> Banner[Display Startup Banner]
    Banner --> AsyncStart[Start Async Context]
    
    AsyncStart --> BuildCapsule[Build VSM Capsule<br/>with Provider/Model]
    BuildCapsule --> StartVSM[Start VSM Task]
    StartVSM --> GenSession[Generate Session UUID]
    GenSession --> CreateReq[Create Analysis Request]
    
    CreateReq --> EmitToVSM[Emit Message to VSM Bus]
    EmitToVSM --> SetupHandlers[Setup Message Handlers]
    SetupHandlers --> StartMonitoring[Start Completion Detection]
    
    subgraph "VSM Message Processing Loop"
        BusMsg[VSM Bus Message] --> RouteMsg{Route by Message Kind}
        
        RouteMsg -->|:user| Intelligence[Intelligence System<br/>Process User Request]
        RouteMsg -->|:tool_call| ToolCall[Handle Tool Call<br/>Update Status]
        RouteMsg -->|:tool_result| ToolResult[Handle Tool Result<br/>Process Data]
        RouteMsg -->|:assistant| Assistant[Handle AI Response<br/>Check Completion]
        RouteMsg -->|:assistant_delta| Delta[Handle Streaming Delta<br/>Display Progress]
        RouteMsg -->|:policy| Policy[Handle Policy Alert<br/>Display Warning]
        RouteMsg -->|:audit| Audit[Handle Audit Event<br/>Log Activity]
        
        Intelligence --> CallTool[Call Operations Tool]
        CallTool --> ToolExec[Tool Execution]
        ToolExec --> ToolResult
        
        ToolResult --> CheckTool{Which Tool?}
        CheckTool -->|load_departments| HandleLoad[Display Department Count]
        CheckTool -->|generate_recommendations| HandleRecs[Display Recommendations<br/>Summary]
        CheckTool -->|create_consolidated_departments| HandleCons[Display Consolidation<br/>Results]
        
        HandleLoad --> NextTool[Continue to Next Tool]
        HandleRecs --> NextTool
        HandleCons --> SetComplete[Set Processing Complete]
        NextTool --> Intelligence
        
        Assistant --> CheckComplete{Check Completion<br/>Patterns}
        CheckComplete -->|Complete| SetComplete
        CheckComplete -->|Continue| BusMsg
        
        Delta --> BusMsg
        Policy --> BusMsg
        Audit --> BusMsg
    end
    
    StartMonitoring --> BusMsg
    SetComplete --> DisplayFinal[Display Final Results]
    DisplayFinal --> Cleanup[Cleanup & Exit]
    Cleanup --> End([Program End])
    
    subgraph "Timeout Detection"
        TimeoutCheck[Check Activity Timeout<br/>Every 5 seconds]
        TimeoutCheck -->|Timeout| ForceComplete[Force Completion]
        TimeoutCheck -->|Active| TimeoutCheck
        ForceComplete --> DisplayFinal
    end
    
    StartMonitoring --> TimeoutCheck
```

## Tool Execution Flow

```mermaid
flowchart TD
    AIRequest[AI Receives Analysis Request] --> ParsePrompt[Parse System Prompt<br/>with Format Examples]
    ParsePrompt --> LoadSample[Load consolidated_department_sample.yml<br/>for Format Specification]
    LoadSample --> Step1[Step 1: Call load_departments]
    
    Step1 --> LoadTool[LoadDepartmentsTool.run]
    LoadTool --> GlobFiles[Glob Pattern: *_department.yml]
    GlobFiles --> SkipTemplate[Skip template files]
    SkipTemplate --> ParseEach[Parse Each YAML File]
    
    ParseEach --> ExtractMeta[Extract Metadata:<br/>• name, display_name<br/>• description, invariants<br/>• capabilities, message_types<br/>• routing_rules, keywords]
    ExtractMeta --> ValidateOpt{Validation Enabled?}
    ValidateOpt -->|Yes| ValidateTemplate[Validate Against Template]
    ValidateOpt -->|No| ReturnData[Return Department Collection]
    ValidateTemplate --> ReturnData
    
    ReturnData --> Step2[Step 2: AI Analyzes Data<br/>Identify Similarities]
    Step2 --> FindOverlaps[Find Capability Overlaps<br/>Keyword Matches<br/>Functional Similarities]
    FindOverlaps --> Step3[Step 3: Call generate_recommendations]
    
    Step3 --> RecTool[RecommendationGeneratorTool.run]
    RecTool --> ProcessCombos[Process Department Combinations]
    ProcessCombos --> CalcScores[Calculate Similarity Scores<br/>• Capability overlap<br/>• Keyword matches<br/>• Infrastructure sharing]
    CalcScores --> EstimateCost[Estimate Cost Savings<br/>• Staff reduction<br/>• Facility consolidation<br/>• Process efficiency]
    EstimateCost --> GenRecords[Generate Recommendation Records]
    GenRecords --> ReturnRecs[Return Recommendations]
    
    ReturnRecs --> Step4[Step 4: AI Formats for<br/>create_consolidated_departments]
    Step4 --> FormatData[Format Data According to<br/>consolidated_department_sample.yml]
    FormatData --> ConsTool[CreateConsolidatedDepartmentsTool.run]
    
    ConsTool --> ValidateInput{Validate Input Format}
    ValidateInput -->|Invalid| ReturnError[Return Format Error]
    ValidateInput -->|Valid| ProcessEach[Process Each Consolidation]
    
    ProcessEach --> FindDeptFiles[Find Department Files<br/>by snake_case names]
    FindDeptFiles --> LoadDepts[Load Department Configs]
    LoadDepts --> MergeConfigs[Merge Configurations<br/>• Combine capabilities<br/>• Merge message types<br/>• Add enhanced features]
    
    MergeConfigs --> GenYAML[Generate New YAML<br/>Following Template Structure]
    GenYAML --> WriteFile[Write Consolidated File]
    WriteFile --> ArchiveOrig[Archive Original Files<br/>Add .doged suffix]
    ArchiveOrig --> ReturnSuccess[Return Success Result]
    
    ReturnError --> Complete[Workflow Complete]
    ReturnSuccess --> Complete
```

## Message Bus Architecture

```mermaid
graph TB
    subgraph "VSM Message Bus"
        Bus[VSM Bus<br/>Central Message Router]
        
        subgraph "Publishers"
            User[User Interface<br/>Analysis Requests]
            Intel[Intelligence System<br/>AI Responses & Tool Calls]
            Tools[Operation Tools<br/>Results & Status]
            Gov[Governance System<br/>Policy & Quality Alerts]
        end
        
        subgraph "Subscribers"
            BaseHandler[Base Controller<br/>Message Handler]
            CoordHandler[Coordination System<br/>Workflow Handler]
            GovHandler[Governance System<br/>Policy Validator]
            IntelHandler[Intelligence System<br/>Context Handler]
        end
        
        subgraph "Message Types"
            UserMsg[:user<br/>Analysis Requests]
            ToolCallMsg[:tool_call<br/>Tool Invocations]
            ToolResultMsg[:tool_result<br/>Tool Results]
            AssistantMsg[:assistant<br/>AI Responses]
            DeltaMsg[:assistant_delta<br/>Streaming Updates]
            PolicyMsg[:policy<br/>Policy Alerts]
            AuditMsg[:audit<br/>Audit Events]
        end
    end
    
    User --> UserMsg
    Intel --> ToolCallMsg
    Intel --> AssistantMsg
    Intel --> DeltaMsg
    Tools --> ToolResultMsg
    Gov --> PolicyMsg
    Gov --> AuditMsg
    
    UserMsg --> Bus
    ToolCallMsg --> Bus
    ToolResultMsg --> Bus
    AssistantMsg --> Bus
    DeltaMsg --> Bus
    PolicyMsg --> Bus
    AuditMsg --> Bus
    
    Bus --> BaseHandler
    Bus --> CoordHandler
    Bus --> GovHandler
    Bus --> IntelHandler
    
    BaseHandler --> StatusUpdate[Status Line Updates]
    BaseHandler --> ResultDisplay[Result Display]
    CoordHandler --> WorkflowMgmt[Workflow Management]
    GovHandler --> QualityCheck[Quality Validation]
    GovHandler --> NameCleanup[Name Sanitization]
    IntelHandler --> ContextMgmt[Context Management]
```

## File System Architecture

```mermaid
graph TB
    subgraph "Input Files"
        YAMLs[Department YAML Files<br/>*_department.yml]
        Template[generic_department_sample.yml<br/>Structure Template]
        ConsolidationSample[consolidated_department_sample.yml<br/>AI Format Specification]
    end
    
    subgraph "DOGE VSM System"
        Main[doge_vsm.rb<br/>Main Entry Point]
        
        subgraph "Core Components"
            Base[base.rb<br/>Controller & UI]
            Identity[identity.rb<br/>Purpose & Invariants]
            Intelligence[intelligence.rb<br/>AI Integration]
            Governance[governance.rb<br/>Quality Control]
            Coordination[coordination.rb<br/>Workflow Management]
            Operations[operations.rb<br/>Tool Registry]
        end
        
        subgraph "Operations Tools"
            LoadTool[load_departments_tool.rb<br/>YAML Parser]
            RecTool[recommendation_generator_tool.rb<br/>Analysis Engine]
            ConsTool[create_consolidated_departments_tool.rb<br/>File Generator]
            ValidTool[template_validation_tool.rb<br/>Structure Validator]
            GenTool[department_template_generator_tool.rb<br/>Template Generator]
        end
    end
    
    subgraph "Output Files"
        ConsolidatedYAMLs[Consolidated Department Files<br/>*_management_department.yml]
        ArchivedFiles[Archived Original Files<br/>*.doged]
        LogFiles[Log Files<br/>log/doge_vsm.log]
    end
    
    YAMLs --> LoadTool
    Template --> ValidTool
    Template --> GenTool
    ConsolidationSample --> Intelligence
    
    Main --> Base
    Base --> Intelligence
    Base --> Operations
    Operations --> LoadTool
    Operations --> RecTool
    Operations --> ConsTool
    Operations --> ValidTool
    Operations --> GenTool
    
    ConsTool --> ConsolidatedYAMLs
    ConsTool --> ArchivedFiles
    Base --> LogFiles
```

## Data Structures

### Department Data Structure
```ruby
{
  file: "utilities_department.yml",
  name: "utilities_department",                    # snake_case identifier
  display_name: "Utilities",                       # Human-readable name
  description: "Maintains city utility infrastructure...",
  invariants: ["serve citizens efficiently", ...], # Operating principles
  capabilities: ["Respond to power outages", ...], # What it can do
  message_types: {                                  # Communication config
    subscribes_to: ["health_check_message", ...],
    publishes: ["power_outage_report", ...]
  },
  routing_rules: { ... },                          # Message routing logic
  message_actions: { ... },                        # Action handlers
  action_configs: { ... },                         # Handler configurations
  ai_analysis: { enabled: true, context: "..." },  # AI integration
  logging: { level: "info", statistics_interval: 300 },
  keywords: ["utility", "power", "infrastructure"], # Extracted keywords
  resources: { ... },                               # Resource management
  integrations: { ... },                           # Service dependencies
  custom_settings: { ... },                        # Department-specific config
  validation: {                                     # Template validation results
    valid: true,
    errors: [],
    warnings: [],
    completeness_score: 85.5
  }
}
```

### Consolidation Input Structure
```ruby
{
  consolidations: {
    "Water & Utilities Management" => {             # New department display name
      old_department_names: [                       # snake_case names to merge
        "water_management_department",
        "utilities_department"
      ],
      reason: "Both departments manage utility infrastructure...",
      enhanced_capabilities: [                      # Synergistic capabilities
        "Unified water infrastructure management...",
        "Cross-trained emergency response teams...",
        "Integrated monitoring systems..."
      ]
    }
  }
}
```

### Tool Result Structure
```ruby
{
  success: true,
  total_consolidations: 3,
  successful_consolidations: 3,
  consolidations: [
    {
      success: true,
      new_department_name: "Water & Utilities Management",
      yaml_file: "water_utilities_management_department.yml",
      merged_departments: [
        { name: "water_management_department", file: "..." },
        { name: "utilities_department", file: "..." }
      ],
      doged_files: [
        { original: "water_management_department.yml", archived: "..." },
        { original: "utilities_department.yml", archived: "..." }
      ],
      capabilities_count: 15
    }
  ],
  summary: {
    new_department_files: ["water_utilities_management_department.yml", ...],
    total_departments_merged: 6,
    total_capabilities: 33
  },
  errors: []
}
```

## Key Features

### 1. AI-Powered Analysis
- Uses LLM providers (OpenAI, Ollama, etc.) for intelligent department analysis
- Identifies capability overlaps, functional similarities, and consolidation opportunities
- Generates detailed reasoning for each recommendation

### 2. Template-Driven Architecture
- `generic_department_sample.yml` ensures consistent department structure
- `consolidated_department_sample.yml` provides exact AI input format specification
- Template validation ensures compliance across all department configurations

### 3. Quality Assurance
- Governance system validates analysis quality and recommendation value
- Template validation ensures structural compliance
- Name sanitization prevents configuration conflicts
- Policy enforcement maintains quality standards

### 4. Comprehensive Tool Suite
- **LoadDepartmentsTool**: Parses and validates YAML configurations
- **RecommendationGeneratorTool**: Generates analysis and cost estimates  
- **CreateConsolidatedDepartmentsTool**: Creates merged department files
- **TemplateValidationTool**: Validates configuration compliance
- **DepartmentTemplateGeneratorTool**: Generates new department templates

### 5. Robust Workflow Management
- Async processing with timeout detection
- Real-time status updates and progress tracking
- Comprehensive logging and error handling
- Message-driven architecture for extensibility

## Usage

### Basic Execution
```bash
ruby doge_vsm.rb
```

### With Custom Provider/Model
```bash
DOGE_LLM_PROVIDER=ollama DOGE_LLM_MODEL=llama3.2:1b ruby doge_vsm.rb
```

### With Debug Output
```bash
VSM_DEBUG_STREAM=1 ruby doge_vsm.rb
```

## Output Files

The system generates several types of output:

1. **Consolidated Departments**: New YAML files combining multiple departments
2. **Archived Originals**: Original files renamed with `.doged` suffix  
3. **Logs**: Detailed execution logs in `log/doge_vsm.log`
4. **Status Updates**: Real-time progress via terminal status line

## Integration Points

### SmartMessage Integration
- Compatible with SmartMessage city scenario system
- Generated departments can be deployed as SmartMessage services
- Maintains message routing and communication patterns

### VSM Architecture Benefits
- Separation of concerns across five VSM systems
- Tool-based architecture enables testing and reuse
- AI integration ready for advanced reasoning
- Policy enforcement ensures quality standards
- Async processing foundation for scalability

This documentation provides a comprehensive understanding of the DOGE VSM system architecture, data flows, and operational patterns.