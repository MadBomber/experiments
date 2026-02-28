# Product Management Skills

> **Goal:** Maximize value delivery using data and prioritization frameworks.
> **Artifacts:** `docs/product/ROADMAP.md`, `docs/product/JTBD.md`

## 1. Prioritization (WSJF)
**Weighted Shortest Job First** is used to prioritize features based on the Cost of Delay divided by Job Duration.

### The Formula
$$ WSJF = \frac{\text{Cost of Delay (CoD)}}{\text{Job Size}} $$

**Cost of Delay Components:**
1.  **User-Business Value:** How valuable is this to the user/business? (1-10)
2.  **Time Criticality:** Is there a fixed deadline? Will we lose customers if we wait? (1-10)
3.  **Risk Reduction / Opportunity Enablement:** Does this reduce risk or open new doors? (1-10)

**Job Size:** Estimated relative effort (Fibonacci: 1, 2, 3, 5, 8, 13...).

## 2. Frameworks

### Jobs To Be Done (JTBD)
Focus on the *outcome* the user wants, not the feature itself.

**Template:**
> **When** [situation]
> **I want to** [motivation]
> **So that I can** [expected outcome]

*Example:*
"When I am hiring a new developer, I want to filter candidates by tech stack, so that I don't waste time interviewing unqualified people."

### RICE Score (Alternative)
- **Reach:** How many people will this impact?
- **Impact:** How much will this move the needle?
- **Confidence:** How sure are we? (0-100%)
- **Effort:** Person-months.

## 3. Roadmapping
Organize features into three buckets (Now, Next, Later) rather than strict timelines.

- **Now:** Detailed specs ready, high WSJF.
- **Next:** Broad scope defined, validation needed.
- **Later:** Long-term vision, subject to change.

## 4. Analytics-Driven Development
If analytics data (Google Analytics, Mixpanel, Amplitude) is available:
1.  **Identify Bottlenecks:** Where do users drop off?
2.  **Feature Usage:** Which features are "zombies" (built but unused)?
3.  **Retention:** Does Feature X correlate with higher retention?
