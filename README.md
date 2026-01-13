# Sagebrush Services Website

A static website for Sagebrush Services built with
[Toucan](https://toucansites.com/), a markdown-based static site generator
written in Swift.

## Claude Code Development Setup

This project is part of the [Trifecta](https://github.com/neon-law-foundation/Trifecta) development environment, designed for full-stack Swift development with Claude Code.

**Recommended Setup**: Use the [Trifecta configuration](https://github.com/neon-law-foundation/Trifecta) which provides:
- Unified Claude Code configuration across all projects
- Pre-configured shell aliases for quick navigation
- Consistent development patterns and tooling
- Automated repository cloning and setup

**Working in Isolation**: This repository can also be developed independently. We maintain separate repositories (rather than a monorepo) to ensure:
- **Clear code boundaries** - Each project has distinct responsibilities and scope
- **Legal delineation** - Clear separation between software consumed by different entities (Neon Law Foundation, Neon Law, Sagebrush Services)
- **Independent deployment** - Each service can be versioned and deployed separately
- **Focused development** - Smaller, more manageable codebases

## Development

### Prerequisites

- Swift 6+
- Toucan CLI (`toucan`)

### Local Development Workflow

1. **Generate the site**

   ```bash
   toucan generate
   ```

   This builds the static site from your markdown content and templates into
   the `dist/` directory.

2. **Start the development server**

   ```bash
   toucan serve
   ```

   This serves the site locally at `http://localhost:3000`.

3. **View your changes**
   Open `http://localhost:3000` in your browser.

4. **Iterate**
   - Make changes to content in `contents/`
   - Edit templates in `templates/`
   - Modify styles in `assets/css/`
   - Run `toucan generate` to rebuild
   - Refresh browser to see changes

### Quick Development Commands

```bash
# One command to generate and serve
toucan generate && toucan serve

# Clean rebuild (removes dist/ first)
rm -rf dist && toucan generate
```

### Building for Production

Build the static site for production deployment:

```bash
toucan generate --target live
```

This generates static HTML/CSS/JS files in the `docs/` directory (configured
for CloudFront deployment).

## Deployment

### CloudFront Distribution

The site is designed to be deployed as a static website via AWS CloudFront:

1. Build the production site: `toucan generate --target live`
2. Upload the `docs/` directory contents to an S3 bucket
3. Configure CloudFront to serve from the S3 bucket
4. Point `www.sagebrush.services` to the CloudFront distribution

## Project Structure

- `contents/` - Markdown content files with YAML frontmatter
- `templates/` - Mustache templates for rendering pages
- `assets/` - Static assets (images, CSS, etc.)
- `site.yml` - Site-wide configuration (name, navigation, etc.)
- `toucan.yml` - Build targets and output configuration
- `docs/` - Generated static site (production build output)

## License

See [LICENSE](LICENSE) for details.
