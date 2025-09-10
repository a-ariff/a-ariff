#!/usr/bin/env python3
"""
Repository Automation Setup Script
Deploys automation workflows and configurations across a-ariff organization repositories
"""

import os
import sys
import json
import argparse
import logging
from pathlib import Path
from typing import List, Dict, Any
import subprocess
import tempfile
import shutil

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class RepositoryAutomationSetup:
    """Setup automation for GitHub repositories"""
    
    def __init__(self, github_token: str, organization: str = "a-ariff"):
        self.github_token = github_token
        self.organization = organization
        self.base_path = Path(__file__).parent.parent
        
    def get_repositories(self) -> List[Dict[str, Any]]:
        """Get all repositories in the organization"""
        try:
            import requests
            
            headers = {
                'Authorization': f'token {self.github_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            repos = []
            page = 1
            
            while True:
                url = f'https://api.github.com/users/{self.organization}/repos'
                params = {'page': page, 'per_page': 100, 'type': 'all'}
                
                response = requests.get(url, headers=headers, params=params)
                response.raise_for_status()
                
                page_repos = response.json()
                if not page_repos:
                    break
                    
                repos.extend(page_repos)
                page += 1
            
            logger.info(f"Found {len(repos)} repositories in {self.organization}")
            return repos
            
        except Exception as e:
            logger.error(f"Error fetching repositories: {e}")
            return []
    
    def detect_repository_type(self, repo_name: str, repo_data: Dict[str, Any]) -> Dict[str, bool]:
        """Detect repository characteristics"""
        repo_type = {
            'is_powershell': False,
            'is_docker': False,
            'is_automation': False,
            'is_security': False,
            'is_intune': False,
            'is_azure': False,
            'is_rust': False,
            'is_python': False,
            'is_documentation': False
        }
        
        name_lower = repo_name.lower()
        description = (repo_data.get('description') or '').lower()
        language = (repo_data.get('language') or '').lower()
        
        # Language-based detection
        if language == 'powershell':
            repo_type['is_powershell'] = True
        elif language == 'rust':
            repo_type['is_rust'] = True
        elif language == 'python':
            repo_type['is_python'] = True
        elif language == 'dockerfile':
            repo_type['is_docker'] = True
        
        # Name-based detection
        automation_keywords = ['automation', 'scripts', 'remediation', 'mdm', 'intune']
        if any(keyword in name_lower for keyword in automation_keywords):
            repo_type['is_automation'] = True
            
        security_keywords = ['security', 'sentinel', 'defender', 'compliance']
        if any(keyword in name_lower for keyword in security_keywords):
            repo_type['is_security'] = True
            
        if 'intune' in name_lower or 'intune' in description:
            repo_type['is_intune'] = True
            
        if 'azure' in name_lower or 'azure' in description:
            repo_type['is_azure'] = True
            
        if 'docker' in name_lower or 'docker' in description:
            repo_type['is_docker'] = True
            
        if repo_name == self.organization:  # Profile repository
            repo_type['is_documentation'] = True
            
        return repo_type
    
    def generate_workflow_config(self, repo_type: Dict[str, bool]) -> Dict[str, Any]:
        """Generate workflow configuration based on repository type"""
        config = {
            'workflows': [],
            'dependabot_ecosystems': ['github-actions'],
            'branch_protection': True,
            'security_scanning': True
        }
        
        # Core workflows for all repositories
        config['workflows'].extend([
            'security-scan.yml',
            'health-check.yml',
            'documentation-sync.yml'
        ])
        
        # PowerShell-specific configurations
        if repo_type['is_powershell']:
            config['dependabot_ecosystems'].extend(['nuget'])
            config['workflows'].append('powershell-quality.yml')
            
        # Docker-specific configurations
        if repo_type['is_docker']:
            config['dependabot_ecosystems'].extend(['docker'])
            config['workflows'].append('docker-security.yml')
            
        # Python-specific configurations
        if repo_type['is_python']:
            config['dependabot_ecosystems'].extend(['pip'])
            config['workflows'].append('python-quality.yml')
            
        # Rust-specific configurations
        if repo_type['is_rust']:
            config['dependabot_ecosystems'].extend(['cargo'])
            config['workflows'].append('rust-quality.yml')
            
        # Security repositories get additional scanning
        if repo_type['is_security'] or repo_type['is_intune']:
            config['workflows'].append('advanced-security-scan.yml')
            
        # Documentation repositories get documentation workflows
        if repo_type['is_documentation']:
            config['workflows'].append('maintenance-report.yml')
            
        return config
    
    def create_dependabot_config(self, ecosystems: List[str]) -> str:
        """Generate Dependabot configuration"""
        config = {
            'version': 2,
            'updates': []
        }
        
        for ecosystem in ecosystems:
            update_config = {
                'package-ecosystem': ecosystem,
                'directory': '/',
                'schedule': {'interval': 'weekly' if ecosystem == 'github-actions' else 'daily'},
                'open-pull-requests-limit': 5,
                'reviewers': [self.organization],
                'assignees': [self.organization],
                'commit-message': {
                    'prefix': 'chore',
                    'include': 'scope'
                },
                'labels': ['dependencies', ecosystem, 'automated']
            }
            
            config['updates'].append(update_config)
        
        return f"# Dependabot configuration\n# Auto-generated by repository automation setup\n\n" + \
               json.dumps(config, indent=2).replace('"', '').replace('{', '').replace('}', '').replace('[', '').replace(']', '').strip()
    
    def setup_repository_automation(self, repo_name: str, repo_data: Dict[str, Any], dry_run: bool = False):
        """Setup automation for a single repository"""
        logger.info(f"Setting up automation for {repo_name}")
        
        # Detect repository type
        repo_type = self.detect_repository_type(repo_name, repo_data)
        logger.info(f"Repository type detected: {repo_type}")
        
        # Generate configuration
        config = self.generate_workflow_config(repo_type)
        logger.info(f"Generated configuration: {config}")
        
        if dry_run:
            logger.info(f"DRY RUN: Would setup automation for {repo_name}")
            return
        
        # Create temporary directory for repository operations
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_dir = Path(temp_dir) / repo_name
            
            try:
                # Clone repository
                logger.info(f"Cloning {repo_name}...")
                subprocess.run([
                    'git', 'clone', 
                    f'https://{self.github_token}@github.com/{self.organization}/{repo_name}.git',
                    str(repo_dir)
                ], check=True, capture_output=True)
                
                # Create .github directory structure
                github_dir = repo_dir / '.github'
                workflows_dir = github_dir / 'workflows'
                workflows_dir.mkdir(parents=True, exist_ok=True)
                
                # Copy workflow files
                source_workflows = self.base_path / '.github' / 'workflows'
                for workflow in config['workflows']:
                    source_file = source_workflows / workflow
                    if source_file.exists():
                        dest_file = workflows_dir / workflow
                        shutil.copy2(source_file, dest_file)
                        logger.info(f"Copied workflow: {workflow}")
                
                # Create Dependabot configuration
                dependabot_config = self.create_dependabot_config(config['dependabot_ecosystems'])
                dependabot_file = github_dir / 'dependabot.yml'
                dependabot_file.write_text(dependabot_config)
                logger.info("Created Dependabot configuration")
                
                # Copy security policy
                security_source = self.base_path / '.github' / 'SECURITY.md'
                if security_source.exists():
                    security_dest = github_dir / 'SECURITY.md'
                    shutil.copy2(security_source, security_dest)
                    logger.info("Copied security policy")
                
                # Copy issue templates
                issue_template_source = self.base_path / '.github' / 'ISSUE_TEMPLATE'
                if issue_template_source.exists():
                    issue_template_dest = github_dir / 'ISSUE_TEMPLATE'
                    if issue_template_dest.exists():
                        shutil.rmtree(issue_template_dest)
                    shutil.copytree(issue_template_source, issue_template_dest)
                    logger.info("Copied issue templates")
                
                # Copy PR template
                pr_template_source = self.base_path / '.github' / 'PULL_REQUEST_TEMPLATE.md'
                if pr_template_source.exists():
                    pr_template_dest = github_dir / 'PULL_REQUEST_TEMPLATE.md'
                    shutil.copy2(pr_template_source, pr_template_dest)
                    logger.info("Copied PR template")
                
                # Commit and push changes
                os.chdir(repo_dir)
                
                # Configure git
                subprocess.run(['git', 'config', 'user.name', 'Repository Automation'], check=True)
                subprocess.run(['git', 'config', 'user.email', 'automation@aglobaltec.com'], check=True)
                
                # Check for changes
                result = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
                if result.stdout.strip():
                    # Add changes
                    subprocess.run(['git', 'add', '.github/'], check=True)
                    
                    # Commit changes
                    commit_message = f"""feat: Add comprehensive repository automation

- Added security scanning workflows (CodeQL, dependency scanning)
- Configured Dependabot for automated dependency updates
- Added repository health monitoring
- Implemented documentation automation
- Added security policy and issue templates
- Configured PR templates and branch protection

Generated by repository automation setup script"""
                    
                    subprocess.run(['git', 'commit', '-m', commit_message], check=True)
                    
                    # Push changes
                    subprocess.run(['git', 'push', 'origin', 'main'], check=True)
                    
                    logger.info(f"Successfully setup automation for {repo_name}")
                else:
                    logger.info(f"No changes needed for {repo_name}")
                    
            except subprocess.CalledProcessError as e:
                logger.error(f"Git operation failed for {repo_name}: {e}")
            except Exception as e:
                logger.error(f"Error setting up automation for {repo_name}: {e}")
    
    def run(self, target_repos: List[str] = None, dry_run: bool = False):
        """Run the automation setup"""
        repositories = self.get_repositories()
        
        if target_repos:
            repositories = [repo for repo in repositories if repo['name'] in target_repos]
        
        logger.info(f"Setting up automation for {len(repositories)} repositories")
        
        for repo in repositories:
            # Skip archived repositories
            if repo.get('archived', False):
                logger.info(f"Skipping archived repository: {repo['name']}")
                continue
                
            self.setup_repository_automation(repo['name'], repo, dry_run)

def main():
    parser = argparse.ArgumentParser(description='Setup repository automation')
    parser.add_argument('--token', required=True, help='GitHub token')
    parser.add_argument('--org', default='a-ariff', help='GitHub organization')
    parser.add_argument('--repos', nargs='+', help='Specific repositories to setup')
    parser.add_argument('--dry-run', action='store_true', help='Dry run mode')
    
    args = parser.parse_args()
    
    setup = RepositoryAutomationSetup(args.token, args.org)
    setup.run(args.repos, args.dry_run)

if __name__ == '__main__':
    main()