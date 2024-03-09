#!/usr/bin/env ruby
# experiments/openai/text_to_speech.rb


require "openai"

client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

input = <<~INPUT

## GPT and LLM Usage Policy for Software Generation:

1. **Mandatory Testing**: All generated code, without exception, must be accompanied by comprehensive tests. These tests should cover not only basic functionality but also edge cases. All tests must pass successfully before the code can be considered for integration into the project.

2. **Side Effects Scrutiny**: Each piece of generated code must be rigorously examined for unwanted or unintended side effects. This involves not only a thorough review of the code itself but also executing it in a secure, isolated environment to observe its behavior under various conditions.

3. **Peer Review Process**: Regardless of its origin (human or AI-generated), all code must undergo a strict peer review process. This review will focus on code quality, security, performance, and adherence to project coding standards. Special attention should be given to verifying that the AI has not introduced biased, unethical, or unsafe content.

4. **Compliance with Legal and Ethical Standards**: Generated code must comply with all applicable legal requirements and ethical considerations. This includes, but is not limited to, respecting copyright laws and ensuring that the code does not perpetuate biases or harm.

5. **Limitations Acknowledgment**: Contributors should be aware of the current limitations of GPT and LLM tools, including their tendency to generate plausible but incorrect or nonsensical code snippets. Critical thinking and developer oversight are essential to filter out such inaccuracies.

6. **Continuous Learning and Adaptation**: As with any emerging technology, the guidelines for GPT and LLM tool usage should be continually evaluated and updated based on new learnings, community standards, and the evolving capabilities of these tools.

By adhering to these guidelines, we aim to harness the innovative power of GPT and LLM technologies while maintaining the highest standards of code quality, security, and ethics. The future of software development is collaborative, blending human ingenuity with AI's capabilities to achieve remarkable outcomes.


INPUT


response = client.audio.speech(
  parameters: {
    model: "tts-1",
    input: input,
    voice: "alloy"
  }
)
File.binwrite('demo.mp3', response)
`afplay demo.mp3`

