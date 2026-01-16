# Technology Stack

This project leverages the following technologies to create a robust and reproducible Kubernetes playground.

## Core Language and Frameworks
- **Go (Golang):** The primary programming language used for all experiments and controller implementations. The project is currently aligned with Go version 1.19.
- **Client-Go:** The official Kubernetes Go client library used for programmatic interaction with the Kubernetes API server.
- **API Machinery:** Core Kubernetes libraries for working with API objects and types.

## Build and Deployment
- **Skaffold:** Handles the workflow for building, pushing, and deploying applications to Kubernetes clusters.
- **Docker:** Used for containerizing applications, with support for both Linux and Windows-based container images.
- **Makefile:** Provides a unified interface for common tasks like building binaries and managing containers.
- **GitHub Actions:** Automates the CI/CD pipeline, specifically for building and deploying the documentation site.

## Infrastructure and Runtime
- **Kind (Kubernetes in Docker):** The primary tool for spinning up local Kubernetes clusters for testing and development.
- **Containerd:** The container runtime of choice, with specific configurations included for deep-dive debugging and inspection.

## Documentation
- **VitePress:** A Vue-based static site generator used to build and serve the project's documentation.
- **GitHub Pages:** Hosts the public documentation site at `mauriciopoppe.github.io/kubernetes-playground`.
