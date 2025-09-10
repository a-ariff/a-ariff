#!/usr/bin/env python3
"""
GitHub Data Collector
=====================

Collects comprehensive data from GitHub API including:
- Repository information and statistics
- Commit history and contribution patterns
- Programming language usage
- Project documentation and README analysis
- Issue and PR activity
- Collaboration patterns

For automated resume generation and portfolio updates.
"""

import requests
import json
import time
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import os
from pathlib import Path

class GitHubDataCollector:
    """Collects and processes GitHub data for career automation."""
    
    def __init__(self, username: str, token: Optional[str] = None):
        """Initialize GitHub data collector.
        
        Args:
            username: GitHub username
            token: GitHub personal access token (optional, but recommended for higher rate limits)
        """
        self.username = username
        self.token = token
        self.base_url = "https://api.github.com"
        self.session = requests.Session()
        
        if token:
            self.session.headers.update({"Authorization": f"token {token}"})
        
        self.logger = logging.getLogger(__name__)
        
        # Data storage
        self.user_data = {}
        self.repositories = []
        self.contributions = {}
        self.languages = {}
        self.collaborations = []
    
    def get_rate_limit(self) -> Dict:
        """Check GitHub API rate limit status."""
        response = self.session.get(f"{self.base_url}/rate_limit")
        return response.json() if response.status_code == 200 else {}
    
    def collect_user_profile(self) -> Dict:
        """Collect user profile information."""
        self.logger.info(f"Collecting profile data for {self.username}")
        
        response = self.session.get(f"{self.base_url}/users/{self.username}")
        if response.status_code == 200:
            self.user_data = response.json()
            self.logger.info("User profile data collected successfully")
        else:
            self.logger.error(f"Failed to collect user profile: {response.status_code}")
        
        return self.user_data
    
    def collect_repositories(self, include_forks: bool = False) -> List[Dict]:
        """Collect repository information and statistics.
        
        Args:
            include_forks: Whether to include forked repositories
        """
        self.logger.info("Collecting repository data...")
        
        page = 1
        per_page = 100
        
        while True:
            params = {
                "page": page,
                "per_page": per_page,
                "sort": "updated",
                "direction": "desc"
            }
            
            response = self.session.get(
                f"{self.base_url}/users/{self.username}/repos",
                params=params
            )
            
            if response.status_code != 200:
                self.logger.error(f"Failed to collect repositories: {response.status_code}")
                break
            
            repos = response.json()
            if not repos:
                break
            
            for repo in repos:
                if not include_forks and repo.get("fork", False):
                    continue
                
                # Enhance repository data with additional statistics
                enhanced_repo = self.enhance_repository_data(repo)
                self.repositories.append(enhanced_repo)
            
            page += 1
            
            # Rate limiting
            time.sleep(0.1)
        
        self.logger.info(f"Collected {len(self.repositories)} repositories")
        return self.repositories
    
    def enhance_repository_data(self, repo: Dict) -> Dict:
        """Enhance repository data with additional statistics and analysis."""
        repo_name = repo["name"]
        
        # Get repository languages
        languages_response = self.session.get(
            f"{self.base_url}/repos/{self.username}/{repo_name}/languages"
        )
        repo["languages"] = languages_response.json() if languages_response.status_code == 200 else {}
        
        # Get repository topics
        topics_response = self.session.get(
            f"{self.base_url}/repos/{self.username}/{repo_name}/topics",
            headers={"Accept": "application/vnd.github.mercy-preview+json"}
        )
        repo["topics"] = topics_response.json().get("names", []) if topics_response.status_code == 200 else []
        
        # Get recent commits for activity analysis
        commits_response = self.session.get(
            f"{self.base_url}/repos/{self.username}/{repo_name}/commits",
            params={"per_page": 10}
        )
        repo["recent_commits"] = commits_response.json() if commits_response.status_code == 200 else []
        
        # Analyze repository complexity and professional relevance
        repo["analysis"] = self.analyze_repository(repo)
        
        time.sleep(0.1)  # Rate limiting
        return repo
    
    def analyze_repository(self, repo: Dict) -> Dict:
        """Analyze repository for professional relevance and complexity."""
        analysis = {
            "complexity_score": 0,
            "professional_relevance": 0,
            "technology_stack": [],
            "project_type": "unknown",
            "documentation_quality": 0
        }
        
        # Analyze by file count and size
        if repo.get("size", 0) > 1000:  # Size in KB
            analysis["complexity_score"] += 2
        
        # Analyze by language diversity
        languages = repo.get("languages", {})
        analysis["technology_stack"] = list(languages.keys())
        
        if len(languages) > 3:
            analysis["complexity_score"] += 1
        
        # Professional relevance based on topics and description
        professional_keywords = [
            "security", "cybersecurity", "azure", "cloud", "automation",
            "devops", "infrastructure", "monitoring", "compliance",
            "enterprise", "kubernetes", "docker", "terraform"
        ]
        
        description = (repo.get("description", "") or "").lower()
        topics = [topic.lower() for topic in repo.get("topics", [])]
        
        for keyword in professional_keywords:
            if keyword in description or keyword in topics:
                analysis["professional_relevance"] += 1
        
        # Determine project type
        if any(word in description for word in ["automation", "script", "tool"]):
            analysis["project_type"] = "automation"
        elif any(word in description for word in ["security", "cyber"]):
            analysis["project_type"] = "security"
        elif any(word in description for word in ["cloud", "azure", "aws"]):
            analysis["project_type"] = "cloud"
        elif any(word in description for word in ["web", "app", "frontend"]):
            analysis["project_type"] = "web_development"
        
        # Documentation quality (basic analysis)
        if repo.get("has_wiki"):
            analysis["documentation_quality"] += 1
        if len(description) > 50:
            analysis["documentation_quality"] += 1
        if repo.get("has_pages"):
            analysis["documentation_quality"] += 1
        
        return analysis
    
    def collect_contribution_stats(self, days: int = 365) -> Dict:
        """Collect contribution statistics over specified period."""
        self.logger.info(f"Collecting contribution stats for last {days} days")
        
        # GitHub doesn't provide direct API for contribution graph
        # This would require GraphQL API or screen scraping
        # For now, we'll calculate from repository commit data
        
        contribution_data = {
            "total_commits": 0,
            "total_additions": 0,
            "total_deletions": 0,
            "active_days": 0,
            "languages_used": set(),
            "repositories_contributed": 0
        }
        
        for repo in self.repositories:
            # Get commits for this repository
            commits_response = self.session.get(
                f"{self.base_url}/repos/{self.username}/{repo['name']}/commits",
                params={
                    "author": self.username,
                    "since": (datetime.now() - timedelta(days=days)).isoformat(),
                    "per_page": 100
                }
            )
            
            if commits_response.status_code == 200:
                commits = commits_response.json()
                if commits:
                    contribution_data["repositories_contributed"] += 1
                    contribution_data["total_commits"] += len(commits)
                    
                    # Add languages from this repository
                    for lang in repo.get("languages", {}).keys():
                        contribution_data["languages_used"].add(lang)
            
            time.sleep(0.1)  # Rate limiting
        
        contribution_data["languages_used"] = list(contribution_data["languages_used"])
        
        self.contributions = contribution_data
        self.logger.info("Contribution stats collected")
        return contribution_data
    
    def analyze_skill_progression(self) -> Dict:
        """Analyze skill progression based on repository history and languages."""
        self.logger.info("Analyzing skill progression...")
        
        skill_progression = {
            "languages_by_year": {},
            "project_complexity_trend": [],
            "technology_adoption": {},
            "expertise_areas": []
        }
        
        # Analyze repositories by creation date
        repos_by_year = {}
        for repo in self.repositories:
            created_at = datetime.fromisoformat(repo["created_at"].replace("Z", "+00:00"))
            year = created_at.year
            
            if year not in repos_by_year:
                repos_by_year[year] = []
            repos_by_year[year].append(repo)
        
        # Analyze language usage by year
        for year, repos in repos_by_year.items():
            year_languages = {}
            for repo in repos:
                for lang, bytes_count in repo.get("languages", {}).items():
                    year_languages[lang] = year_languages.get(lang, 0) + bytes_count
            
            skill_progression["languages_by_year"][year] = year_languages
        
        # Identify expertise areas based on consistent language usage and project types
        all_languages = {}
        security_projects = 0
        cloud_projects = 0
        automation_projects = 0
        
        for repo in self.repositories:
            # Count language usage
            for lang, bytes_count in repo.get("languages", {}).items():
                all_languages[lang] = all_languages.get(lang, 0) + bytes_count
            
            # Count project types
            project_type = repo.get("analysis", {}).get("project_type", "")
            if project_type == "security":
                security_projects += 1
            elif project_type == "cloud":
                cloud_projects += 1
            elif project_type == "automation":
                automation_projects += 1
        
        # Determine expertise areas
        if security_projects >= 3:
            skill_progression["expertise_areas"].append("Cybersecurity")
        if cloud_projects >= 3:
            skill_progression["expertise_areas"].append("Cloud Computing")
        if automation_projects >= 5:
            skill_progression["expertise_areas"].append("Automation & DevOps")
        
        # Top languages by usage
        top_languages = sorted(all_languages.items(), key=lambda x: x[1], reverse=True)[:10]
        skill_progression["top_languages"] = [lang for lang, _ in top_languages]
        
        return skill_progression
    
    def save_data(self, output_dir: str = "automation/data"):
        """Save collected data to JSON files."""
        self.logger.info(f"Saving GitHub data to {output_dir}")
        
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Save individual data files
        datasets = {
            "user_profile.json": self.user_data,
            "repositories.json": self.repositories,
            "contributions.json": self.contributions,
            "skill_progression.json": self.analyze_skill_progression()
        }
        
        for filename, data in datasets.items():
            with open(output_path / filename, 'w') as f:
                json.dump(data, f, indent=2, default=str)
        
        # Create summary report
        summary = {
            "collection_date": datetime.now().isoformat(),
            "username": self.username,
            "total_repositories": len(self.repositories),
            "public_repos": self.user_data.get("public_repos", 0),
            "followers": self.user_data.get("followers", 0),
            "following": self.user_data.get("following", 0),
            "account_created": self.user_data.get("created_at", ""),
            "last_updated": self.user_data.get("updated_at", ""),
            "rate_limit_remaining": self.get_rate_limit().get("rate", {}).get("remaining", 0)
        }
        
        with open(output_path / "github_summary.json", 'w') as f:
            json.dump(summary, f, indent=2)
        
        self.logger.info("GitHub data saved successfully")
    
    def collect_all_data(self) -> Dict:
        """Collect all GitHub data in one operation."""
        self.logger.info("Starting comprehensive GitHub data collection...")
        
        # Check rate limit before starting
        rate_limit = self.get_rate_limit()
        remaining = rate_limit.get("rate", {}).get("remaining", 0)
        
        if remaining < 100:
            self.logger.warning(f"Low rate limit remaining: {remaining}")
        
        # Collect data
        self.collect_user_profile()
        self.collect_repositories(include_forks=False)
        self.collect_contribution_stats()
        
        # Save data
        self.save_data()
        
        self.logger.info("GitHub data collection completed")
        
        return {
            "user_data": self.user_data,
            "repositories": self.repositories,
            "contributions": self.contributions,
            "skill_progression": self.analyze_skill_progression()
        }

def main():
    """Test the GitHub data collector."""
    logging.basicConfig(level=logging.INFO)
    
    # Get GitHub token from environment
    token = os.getenv("GITHUB_TOKEN")
    username = "a-ariff"
    
    collector = GitHubDataCollector(username, token)
    collector.collect_all_data()

if __name__ == "__main__":
    main()