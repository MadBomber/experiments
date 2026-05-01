# Common Hyperbolic Language Patterns to Avoid

This reference documents the marketing superlatives and inflated claims that undermine credibility in software announcements. Instead of these patterns, favor specific facts, concrete examples, and honest limitations.

## Superlatives to Replace

### "Revolutionary" / "Game-changing" / "Paradigm shift"
- **Problem**: These claim the software fundamentally changes the industry without evidence
- **Example to avoid**: "TypedBus is a revolutionary approach to pub/sub messaging"
- **Better**: "TypedBus is a lightweight, fiber-based pub/sub message bus for Ruby" (what it actually is)

### "Best-in-class" / "Industry-leading" / "State-of-the-art"
- **Problem**: Unsubstantiated competitive claims
- **Example to avoid**: "The best release notes formatter available"
- **Better**: "Formats release notes with explicit structure" (what it does)

### "Incredibly" / "Amazingly" / "Powerful" (when unsupported)
- **Problem**: Emotional amplification without basis
- **Example to avoid**: "An incredibly powerful new feature"
- **Better**: "Supports concurrent multi-model execution with per-model role assignment" (specific capability)

### "Unlimited" / "Infinite" / "Endless"
- **Problem**: Technical claims that are never true
- **Example to avoid**: "Unlimited scalability"
- **Better**: "Tested with 1000s of concurrent fibers" (actual tested limit) or "Bounded by available RAM and fiber overhead" (honest boundary)

### "Always" / "Never" (in absolute contexts)
- **Problem**: Edge cases exist
- **Example to avoid**: "Never need to worry about synchronization again"
- **Better**: "No mutexes required; uses fibers for concurrent work" (how it works)

## Vague Benefit Claims to Concretize

### "Easier / Simpler / Better"
- **Problem**: Subjective without comparison
- **Example to avoid**: "Easier to use than other solutions"
- **Better**: Compare against alternatives with specific examples, or describe the concrete interface

### "Faster / Slower" (without metrics)
- **Problem**: Speed claims need benchmarks
- **Example to avoid**: "Much faster performance"
- **Better**: "Multi-model queries run in parallel; wall-clock time is roughly the slowest model, not the sum" (how it works + what you'll observe)

### "Handles edge cases better"
- **Problem**: Assumes all cases equally
- **Example to avoid**: "Better error handling"
- **Better**: "Failed deliveries are collected in a dead letter queue for inspection and retry" (what happens in failure mode)

## Emotional Language to Neutralize

### Excitement markers
- **Avoid**: Multiple exclamation marks, "excited to share," "thrilled to announce"
- **Better**: "I'm happy to share" (honest but measured)

### Superlatives about team/creation
- **Avoid**: "Our brilliant team crafted..." "We've poured our hearts into..."
- **Better**: "This release ships with the new .md prompt format, ERB parameters, MCP integration, and 774 tests passing" (focus on what was built, not the people or process)

## What To Include Instead

### Specific numbers and limits
- Test count: "774 tests passing"
- Performance baselines: "Tested with 1000+ concurrent fibers"
- Supported platforms: "Works with OpenAI, Anthropic, Google, DeepSeek, Mistral, Ollama, LM Studio..."
- Token costs: "Per-model token counts and actual cost, plus projected cost at scale (x1000)"

### Real-world use cases
- "I replaced browser search with an AIA chat session in a terminal tab" (personal experience)
- "The question that matters is: 'what does this prompt cost with this model?'" (problem it solves)

### Honest limitations
- "Not always. But often enough..." (acknowledging that the typical case isn't universal)
- Breaking changes listed explicitly
- Migration required/tools provided
- Dependencies and requirements stated clearly

### Code examples
- Show actual usage patterns
- Demonstrate the actual interface users will write
- Include realistic parameters and configurations

### Performance trade-offs
- "No threads. No mutexes. Just fibers..." (mechanism, not magic)
- Explain what the implementation choice buys and costs
- Benchmark data when available
