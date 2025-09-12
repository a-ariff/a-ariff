#!/usr/bin/env python3
"""
Branch Protection Setup Script
Configures branch protection rules across repositories
"""

import os
import sys
import json
import argparse
import logging
from typing import List, Dict, Any
import requests

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class BranchProtectionSetup:
    """Setup branch protection rules for repositories"""
    
    def __init__(self, github_token: str, organization: str = "a-ariff"):
        self.github_token = github_token
        self.organization = organization
        self.headers = {
            'Authorization': f'token {github_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
    
    def get_default_protection_config(self) -> Dict[str, Any]:
        """Get default branch protection configuration"""
        return {
            "required_status_checks": {
                "strict": True,
                "contexts": [
                    "Security Scanning Suite",
                    "Repository Health Check"
                ]
            },
            "enforce_admins": False,
            "required_pull_request_reviews": {
                "required_approving_review_count": 1,
                "dismiss_stale_reviews": True,
                "require_code_owner_reviews": True,
                "dismissal_restrictions": {}
            },
            "restrictions": None,
            "allow_force_pushes": False,
            "allow_deletions": False,
            "block_creations": False,
            "required_conversation_resolution": True
        }
    
    def get_enhanced_protection_config(self) -> Dict[str, Any]:
        """Get enhanced branch protection for critical repositories"""
        config = self.get_default_protection_config()
        config["required_pull_request_reviews"]["required_approving_review_count"] = 2
        config["enforce_admins"] = True
        config["required_status_checks"]["contexts"].extend([
            "CodeQL",
            "Dependency Scanning"
        ])
        return config
    
    def setup_branch_protection(self, repo_name: str, branch: str = "main", enhanced: bool = False):
        """Setup branch protection for a repository"""
        try:
            # Get repository information
            repo_url = f'https://api.github.com/repos/{self.organization}/{repo_name}'
            repo_response = requests.get(repo_url, headers=self.headers)
            repo_response.raise_for_status()
            repo_data = repo_response.json()
            
            # Check if repository is archived
            if repo_data.get('archived', False):
                logger.info(f"Skipping archived repository: {repo_name}")
                return False
            
            # Get branch protection configuration
            config = self.get_enhanced_protection_config() if enhanced else self.get_default_protection_config()
            
            # Determine if repository needs enhanced protection
            critical_repos = [
                'intune-remediation-scripts',
                'azure-automation-hub',
                'msgraph-automation-scripts',
                'browser-popup-mdm-automation'
            ]
            
            if repo_name in critical_repos:
                config = self.get_enhanced_protection_config()
                logger.info(f"Using enhanced protection for critical repository: {repo_name}")
            
            # Apply branch protection
            protection_url = f'https://api.github.com/repos/{self.organization}/{repo_name}/branches/{branch}/protection'
            
            response = requests.put(protection_url, headers=self.headers, json=config)
            
            if response.status_code == 200:
                logger.info(f"✅ Updated branch protection for {repo_name}:{branch}")
                return True
            elif response.status_code == 404:
                logger.warning(f"⚠️ Branch {branch} not found in {repo_name}")
                return False
            else:
                logger.error(f"❌ Failed to setup branch protection for {repo_name}: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Error setting up branch protection for {repo_name}: {e}")
            return False
    
    def get_repositories(self) -> List[Dict[str, Any]]:
        """Get all repositories in the organization"""
        try:
            repos = []
            page = 1
            
            while True:
                url = f'https://api.github.com/users/{self.organization}/repos'
                params = {'page': page, 'per_page': 100, 'type': 'all'}
                
                response = requests.get(url, headers=self.headers, params=params)
                response.raise_for_status()
                
                page_repos = response.json()
                if not page_repos:
                    break
                    
                repos.extend(page_repos)
                page += 1
            
            return repos
            
        except Exception as e:
            logger.error(f"Error fetching repositories: {e}")
            return []
    
    def run(self, target_repos: List[str] = None, enhanced: bool = False):
        """Run branch protection setup"""
        repositories = self.get_repositories()
        
        if target_repos:
            repositories = [repo for repo in repositories if repo['name'] in target_repos]
        
        logger.info(f"Setting up branch protection for {len(repositories)} repositories")
        
        success_count = 0
        failed_count = 0
        
        for repo in repositories:
            repo_name = repo['name']
            
            # Skip archived repositories
            if repo.get('archived', False):
                logger.info(f"Skipping archived repository: {repo_name}")
                continue
            
            # Try main branch first, then master
            branches_to_try = ['main', 'master']
            protected = False
            
            for branch in branches_to_try:
                if self.setup_branch_protection(repo_name, branch, enhanced):
                    success_count += 1
                    protected = True
                    break
            
            if not protected:
                failed_count += 1
        
        logger.info(f"Branch protection setup complete: {success_count} successful, {failed_count} failed")
        return success_count, failed_count

def main():
    parser = argparse.ArgumentParser(description='Setup branch protection rules')
    parser.add_argument('--token', required=True, help='GitHub token')
    parser.add_argument('--org', default='a-ariff', help='GitHub organization')
    parser.add_argument('--repos', nargs='+', help='Specific repositories to setup')
    parser.add_argument('--enhanced', action='store_true', help='Use enhanced protection rules')
    
    args = parser.parse_args()
    
    setup = BranchProtectionSetup(args.token, args.org)
    setup.run(args.repos, args.enhanced)

if __name__ == '__main__':
    main()