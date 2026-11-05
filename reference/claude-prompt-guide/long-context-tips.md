# Long Context Prompting Tips

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/long-context-tips

---

## Overview

Claude's extended context window (200K tokens for Claude 3 models) enables handling complex, data-rich tasks. This guide will help you leverage this power effectively.

## Essential Tips for Long Context Prompts

### 1. Put Longform Data at the Top

**Place your long documents and inputs (~20K+ tokens) near the top of your prompt, above your query, instructions, and examples.**

This can significantly improve Claude's performance across all models.

**Performance impact**: Queries at the end can improve response quality by up to **30%** in tests, especially with complex, multi-document inputs.

**Example structure:**
```
<documents>
{{LONG_DOCUMENT_1}}
{{LONG_DOCUMENT_2}}
{{LONG_DOCUMENT_3}}
</documents>

[Your instructions and query here]
```

### 2. Structure Document Content and Metadata with XML Tags

When using multiple documents, wrap each document in `<document>` tags with `<document_content>` and `<source>` (and other metadata) subtags for clarity.

**Example multi-document structure:**
```xml
<documents>
  <document index="1">
    <source>annual_report_2023.pdf</source>
    <document_content>
      {{ANNUAL_REPORT}}
    </document_content>
  </document>

  <document index="2">
    <source>competitor_analysis_q2.xlsx</source>
    <document_content>
      {{COMPETITOR_ANALYSIS}}
    </document_content>
  </document>
</documents>

Analyze the annual report and competitor analysis. Identify strategic advantages
and recommend Q3 focus areas.
```

**Benefits:**
- Clear document boundaries
- Easy reference by index or source name
- Metadata helps Claude understand context
- Better parsing and accuracy

### 3. Ground Responses in Quotes

For long document tasks, ask Claude to **quote relevant parts of the documents first** before carrying out its task. This helps Claude cut through the "noise" of the rest of the document's contents.

**Example quote extraction:**
```xml
You are an AI physician's assistant. Your task is to help doctors diagnose possible
patient illnesses.

<documents>
  <document index="1">
    <source>patient_symptoms.txt</source>
    <document_content>
      {{PATIENT_SYMPTOMS}}
    </document_content>
  </document>

  <document index="2">
    <source>patient_records.txt</source>
    <document_content>
      {{PATIENT_RECORDS}}
    </document_content>
  </document>

  <document index="3">
    <source>patient01_appt_history.txt</source>
    <document_content>
      {{PATIENT01_APPOINTMENT_HISTORY}}
    </document_content>
  </document>
</documents>

Find quotes from the patient records and appointment history that are relevant to
diagnosing the patient's reported symptoms. Place these in <quotes> tags.

Then, based on these quotes, list all information that would help the doctor
diagnose the patient's symptoms. Place your diagnostic information in <info> tags.
```

**Why this works:**
- Forces Claude to identify relevant sections first
- Reduces hallucination risk
- Creates traceable reasoning
- Improves accuracy on complex documents

## Best Practices

### Document Organization

1. **Use consistent tagging** - Same structure for all documents
2. **Include metadata** - Source, date, author, document type
3. **Number or index documents** - Easy reference
4. **Separate concerns** - Use different tags for different content types

### Query Placement

❌ **Bad:**
```
Analyze this report: {{50K_TOKEN_REPORT}}

What are the key findings?
```

✅ **Good:**
```
<document>
{{50K_TOKEN_REPORT}}
</document>

Based on the report above, what are the key findings?
```

### Multi-Document Queries

❌ **Bad:**
```
Here are three reports {{DOC1}} {{DOC2}} {{DOC3}}. Compare them.
```

✅ **Good:**
```
<documents>
  <document index="1">
    <title>Q1 Report</title>
    <content>{{DOC1}}</content>
  </document>
  <document index="2">
    <title>Q2 Report</title>
    <content>{{DOC2}}</content>
  </document>
  <document index="3">
    <title>Q3 Report</title>
    <content>{{DOC3}}</content>
  </document>
</documents>

Compare the three quarterly reports above. Identify trends and anomalies.
```

## Advanced Techniques

### Citation-Based Reasoning

```xml
<documents>
{{MULTIPLE_RESEARCH_PAPERS}}
</documents>

<instructions>
1. First, extract relevant quotes from the papers in <quotes> tags
2. Then, synthesize findings in <synthesis> tags
3. Finally, provide recommendations in <recommendations> tags

Always cite document index and approximate location for each quote.
</instructions>
```

### Hierarchical Document Structure

```xml
<project>
  <specifications>
    <functional_requirements>{{FUNC_REQS}}</functional_requirements>
    <technical_requirements>{{TECH_REQS}}</technical_requirements>
  </specifications>

  <implementation>
    <codebase>{{CODE}}</codebase>
    <tests>{{TESTS}}</tests>
  </implementation>

  <documentation>
    <user_guide>{{USER_GUIDE}}</user_guide>
    <api_docs>{{API_DOCS}}</api_docs>
  </documentation>
</project>

Review the entire project for consistency between specifications, implementation,
and documentation. Flag any discrepancies.
```

### Focused Extraction Before Analysis

```
<large_dataset>
{{100K_TOKEN_DATASET}}
</large_dataset>

Step 1: Extract all entries related to "customer churn" and place them in
<churn_data> tags.

Step 2: Analyze the extracted churn data and provide insights.
```

## Common Pitfalls

❌ **Avoid:**
- Putting query at the top, documents at the bottom
- Mixing documents without clear boundaries
- No structure or metadata
- Asking complex questions without grounding in quotes first

✅ **Do:**
- Documents first, query last
- Clear XML structure with metadata
- Quote-based reasoning for complex analysis
- Break down multi-step analysis into subtasks

## Performance Optimization

### Token Budget Management

- Claude 3 models: 200K token context window
- Reserve ~10% for output (20K tokens)
- Leaves ~180K for input (documents + prompt)
- Structure matters more than length

### Caching Opportunities

When using prompt caching:
- Put static documents in cacheable sections
- Change only query/instructions between requests
- Can reduce costs significantly for repeated analysis

## Use Cases

### Legal Document Review
```xml
<contracts>
  <contract id="1">
    <source>vendor_agreement_2024.pdf</source>
    <content>{{CONTRACT_1}}</content>
  </contract>
  <!-- More contracts -->
</contracts>

Review all contracts for non-standard liability clauses. Quote relevant sections.
```

### Research Synthesis
```xml
<papers>
  <paper id="1">
    <title>{{TITLE_1}}</title>
    <authors>{{AUTHORS_1}}</authors>
    <content>{{PAPER_1}}</content>
  </paper>
  <!-- More papers -->
</papers>

Synthesize findings on "climate change impact on agriculture" from these papers.
```

### Code Review
```xml
<codebase>
  <file path="src/auth.py">{{AUTH_CODE}}</file>
  <file path="src/database.py">{{DB_CODE}}</file>
  <file path="tests/test_auth.py">{{TEST_CODE}}</file>
</codebase>

Review authentication implementation for security vulnerabilities.
```

## Resources

- [Prompt library](https://platform.claude.com/docs/en/resources/prompt-library/library)
- [GitHub prompting tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)
- [Google Sheets prompting tutorial](https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8)
- [Prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
