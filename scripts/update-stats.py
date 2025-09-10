#!/usr/bin/env python3
"""
GitHub Stats Update Script
Updates README.md with fresh GitHub statistics and metrics
"""

import requests
import json
import os
from datetime import datetime
import re

def get_github_stats(username):
    """Fetch GitHub user statistics"""
    try:
        # GitHub API calls (no auth needed for public data)
        user_url = f"https://api.github.com/users/{username}"
        repos_url = f"https://api.github.com/users/{username}/repos?per_page=100"
        
        user_response = requests.get(user_url)
        repos_response = requests.get(repos_url)
        
        if user_response.status_code == 200 and repos_response.status_code == 200:
            user_data = user_response.json()
            repos_data = repos_response.json()
            
            # Calculate statistics
            total_stars = sum(repo['stargazers_count'] for repo in repos_data)
            total_forks = sum(repo['forks_count'] for repo in repos_data)
            languages = {}
            
            for repo in repos_data:
                if repo['language']:
                    languages[repo['language']] = languages.get(repo['language'], 0) + 1
            
            return {
                'public_repos': user_data['public_repos'],
                'followers': user_data['followers'],
                'following': user_data['following'],
                'total_stars': total_stars,
                'total_forks': total_forks,
                'top_languages': sorted(languages.items(), key=lambda x: x[1], reverse=True)[:5],
                'last_updated': datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
            }
    except Exception as e:
        print(f"Error fetching GitHub stats: {e}")
        return None

def update_readme_stats(username):
    """Update README.md with fresh statistics"""
    stats = get_github_stats(username)
    if not stats:
        return False
    
    readme_path = "README.md"
    if not os.path.exists(readme_path):
        return False
    
    with open(readme_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update last updated timestamp (add if not exists)
    timestamp_pattern = r'<!-- STATS_LAST_UPDATED:.*?-->'
    new_timestamp = f"<!-- STATS_LAST_UPDATED:{stats['last_updated']} -->"
    
    if re.search(timestamp_pattern, content):
        content = re.sub(timestamp_pattern, new_timestamp, content)
    else:
        # Add timestamp before closing div
        content = content.replace('</div>\n\n---', f'{new_timestamp}\n\n</div>\n\n---')
    
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Updated README stats for {username}")
    print(f"📊 Repos: {stats['public_repos']}, Followers: {stats['followers']}, Stars: {stats['total_stars']}")
    return True

if __name__ == "__main__":
    username = os.getenv('GITHUB_USERNAME', 'a-ariff')
    success = update_readme_stats(username)
    if not success:
        exit(1)