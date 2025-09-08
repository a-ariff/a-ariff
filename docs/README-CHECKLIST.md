# README Maintenance Checklist

Use this checklist when updating README files to prevent display and compatibility issues.

## Before Making Changes

### 📋 Pre-Change Checklist
- [ ] **Backup current version**: Create a backup of the working README
- [ ] **Review maintenance guide**: Check `docs/README-MAINTENANCE.md` for latest guidelines
- [ ] **Test locally**: Preview changes in a local markdown viewer
- [ ] **Check character encoding**: Ensure file is saved as UTF-8 without BOM

## During Changes

### ✏️ Content Guidelines
- [ ] **Avoid problematic Unicode**: No block characters (█▓░), box drawing (├┌└), or complex symbols
- [ ] **Use safe alternatives**: Replace progress bars with badges or descriptive text
- [ ] **Test internal links**: Verify all anchor links point to existing headings
- [ ] **Validate external URLs**: Check that all external links are accessible
- [ ] **Optimize images**: Ensure images load quickly and have alt text
- [ ] **Use standard emoji**: Stick to widely supported emoji characters

### 🔧 Technical Checks
- [ ] **Valid markdown syntax**: Use a linter to check for syntax errors
- [ ] **Cross-platform compatibility**: Avoid vendor-specific markdown extensions
- [ ] **Accessibility**: Ensure content is accessible to screen readers
- [ ] **Mobile-friendly**: Test that content displays well on mobile devices

## After Making Changes

### 🧪 Testing Checklist
- [ ] **GitHub web preview**: View the file on GitHub in both light and dark modes
- [ ] **Mobile testing**: Check appearance on GitHub mobile app
- [ ] **Browser testing**: Test in Chrome, Firefox, Safari, and Edge
- [ ] **Link validation**: Run the link checker workflow or test manually
- [ ] **Badge verification**: Ensure all external badges load correctly
- [ ] **Raw text view**: Check that content is readable in plain text

### 🚀 Deployment Checks
- [ ] **Run validation workflow**: Ensure the README validation GitHub Action passes
- [ ] **Monitor for issues**: Check for any reported display problems
- [ ] **Update documentation**: Record any new patterns or solutions used
- [ ] **Version control**: Tag or document significant README changes

## Periodic Maintenance (Monthly)

### 🔄 Regular Maintenance Tasks
- [ ] **Link health check**: Run link checker to identify broken URLs
- [ ] **Badge service status**: Verify external badge services are responding
- [ ] **Content freshness**: Update statistics, achievements, and current projects
- [ ] **Certification updates**: Add new certifications and remove expired ones
- [ ] **Contact information**: Ensure all contact details are current
- [ ] **Project references**: Update links to featured projects and repositories

### 📊 Performance Review
- [ ] **Loading speed**: Check that the README loads quickly with all external resources
- [ ] **Image optimization**: Ensure images are optimized and accessible
- [ ] **Dependency health**: Monitor the reliability of external services used
- [ ] **Analytics review**: Check profile view statistics and engagement metrics

## Emergency Response

### 🚨 If Issues Occur
1. **Immediate action**: Revert to the last known good version
2. **Identify the problem**: Use git diff to find what changed
3. **Quick fix**: Address the specific issue with minimal changes
4. **Test thoroughly**: Verify the fix works across platforms
5. **Document learning**: Update maintenance guides with new insights

### 📞 Escalation Process
- For urgent display issues: Revert immediately and investigate later
- For broken links: Use .lycheeignore to temporarily exclude problematic URLs
- For external service failures: Consider alternative badge services or text replacements
- For encoding issues: Re-save the file with proper UTF-8 encoding

## Version History Tracking

### 📝 Change Documentation
- [ ] **Commit messages**: Use clear, descriptive commit messages for README changes
- [ ] **Change rationale**: Document why changes were made
- [ ] **Testing results**: Record what testing was performed
- [ ] **Known issues**: Document any temporary workarounds or limitations

---

## Quick Reference

### Approved Alternatives
- **Progress bars** → Badge shields or descriptive text
- **Unicode symbols** → Standard emoji or ASCII characters  
- **Complex layouts** → Simple tables or lists
- **External dependencies** → Local content where possible

### Emergency Contacts
- Repository maintainer: Ariff Mohamed
- Documentation: `docs/README-MAINTENANCE.md`
- Templates: `docs/README-TEMPLATES.md`
- Validation: `.github/workflows/readme-validation.yml`

---

*Print or bookmark this checklist for quick reference during README updates.*