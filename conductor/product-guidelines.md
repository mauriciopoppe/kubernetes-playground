# Product Guidelines

This document outlines the principles and standards for documentation and organization within the Kubernetes Playground.

## Documentation Standards
- **Prose Style:** Use a technical and formal voice. Documentation should be objective, precise, and structured, mimicking the style of official Kubernetes documentation to ensure clarity and professional consistency.
- **Depth and Balance:** Prioritize thorough documentation. Every experiment or technical note must include a detailed Markdown file. This file should clearly explain the underlying Kubernetes concept, the specific setup of the experiment, and a comprehensive analysis of the observed results.
- **Clarity and Precision:** Technical terms should be used accurately. Avoid ambiguity by providing specific details about configurations, versions, and environment setup.

## Project Organization
- **Flat Structure:** Keep all experiments in the root or a single `experiments/` directory. This structure simplifies access and keeps all items at the same level of hierarchy.
- **Consistency:** Maintain a consistent naming convention for files and directories to ensure clarity and ease of access.

## Content Integrity
- **Verified Experiments:** Ensure that all shared experiments are reproducible. Include necessary prerequisites and clear instructions for setting up the environment (e.g., Kind cluster configuration, Skaffold commands).
- **Update Frequency:** As personal insights evolve or Kubernetes versions change, documentation should be updated to reflect the most current and accurate information.
