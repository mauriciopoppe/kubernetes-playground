# Specification: GitHub Actions Deployment

## 1. Overview
The goal of this track is to automate the deployment of the VitePress-based documentation site to GitHub Pages using GitHub Actions. The site will be accessible at `mauriciopoppe.github.io/kubernetes-playground`.

## 2. Functional Requirements
- **VitePress Configuration:** Update `docs/.vitepress/config.js` to set the `base` configuration to `/kubernetes-playground/`.
- **GitHub Actions Workflow:**
    - Create a `.github/workflows/deploy.yml` file.
    - Configure the workflow to trigger on every push to the `master` branch.
    - Add steps to:
        1. Checkout the repository.
        2. Set up Node.js.
        3. Install dependencies.
        4. Build the VitePress site (`npm run docs:build`).
        5. Upload the build artifacts (`docs/.vitepress/dist`).
        6. Deploy to GitHub Pages using the official `actions/deploy-pages`.
- **Permissions:** Ensure the workflow has the necessary `pages: write` and `id-token: write` permissions.

## 3. Non-Functional Requirements
- **Efficiency:** The deployment should be fast and reliable.
- **Security:** Use official and well-maintained GitHub Actions.
- **Minimalism:** Keep the workflow simple and focused on the deployment task.

## 4. Acceptance Criteria
- [ ] `docs/.vitepress/config.js` is updated with `base: '/kubernetes-playground/'`.
- [ ] `.github/workflows/deploy.yml` exists and is correctly configured.
- [ ] Pushing to the `master` branch triggers the deployment workflow.
- [ ] The VitePress site is successfully built and deployed to GitHub Pages.
- [ ] The site at `mauriciopoppe.github.io/kubernetes-playground` is accessible and displays correctly (assets load correctly).

## 5. Out of Scope
- Configuring custom domains.
- Setting up deployments for other branches or environments.
