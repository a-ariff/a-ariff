#!/usr/bin/env python3
"""
Recent Activity Update Script
Updates README.md with recent GitHub activity
"""

import requests
import json
import os
from datetime import datetime
import re

def get_recent_activity(username, token=None):
    """Fetch recent GitHub activity"""
    try:
        headers = {}
        if token:
            headers['Authorization'] = f'token {token}'
        
        # Get recent events
        events_url = f"https://api.github.com/users/{username}/events/public"
        response = requests.get(events_url, headers=headers)
        
        if response.status_code == 200:
            events = response.json()[:5]  # Get latest 5 events
            
            activity_lines = []
            for event in events:
                event_type = event['type']
                repo_name = event['repo']['name']
                created_at = datetime.strptime(event['created_at'], '%Y-%m-%dT%H:%M:%SZ')
                
                # Format activity based on event type
                if event_type == 'PushEvent':
                    commits = len(event['payload']['commits'])
                    activity_lines.append(f"⬆️ Pushed {commits} commit{'s' if commits > 1 else ''} to [{repo_name}](https://github.com/{repo_name})")
                elif event_type == 'CreateEvent':
                    ref_type = event['payload']['ref_type']
                    activity_lines.append(f"🎉 Created {ref_type} in [{repo_name}](https://github.com/{repo_name})")
                elif event_type == 'IssuesEvent':
                    action = event['payload']['action']
                    activity_lines.append(f"❗ {action.title()} issue in [{repo_name}](https://github.com/{repo_name})")
                elif event_type == 'PullRequestEvent':
                    action = event['payload']['action']
                    activity_lines.append(f"💪 {action.title()} pull request in [{repo_name}](https://github.com/{repo_name})")
                elif event_type == 'WatchEvent':
                    activity_lines.append(f"⭐ Starred [{repo_name}](https://github.com/{repo_name})")
                elif event_type == 'ForkEvent':
                    activity_lines.append(f"🍴 Forked [{repo_name}](https://github.com/{repo_name})")
                else:
                    activity_lines.append(f"📝 {event_type.replace('Event', '')} in [{repo_name}](https://github.com/{repo_name})")
            
            return activity_lines[:5]  # Limit to 5 activities
            
    except Exception as e:
        print(f"Error fetching recent activity: {e}")
        return ["🔄 Unable to fetch recent activity"]

def update_recent_activity(username, token=None):
    """Update README.md with recent activity"""
    activities = get_recent_activity(username, token)
    if not activities:
        activities = ["🔄 Unable to fetch recent activity"]
    
    readme_path = "README.md"
    if not os.path.exists(readme_path):
        return False
    
    with open(readme_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update recent activity section
    start_marker = "<!-- START_SECTION:activity -->"
    end_marker = "<!-- END_SECTION:activity -->"
    
    if start_marker in content and end_marker in content:
        # Build new activity section
        new_activity = f"{start_marker}\n"
        for activity in activities:
            new_activity += f"- {activity}\n"
        new_activity += end_marker
        
        # Replace the section
        pattern = f"{re.escape(start_marker)}.*?{re.escape(end_marker)}"
        content = re.sub(pattern, new_activity, content, flags=re.DOTALL)
        
        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✅ Updated recent activity for {username}")
        return True
    else:
        print("❌ Activity markers not found in README.md")
        return False

if __name__ == "__main__":
    username = os.getenv('GITHUB_USERNAME', 'a-ariff')
    token = os.getenv('GITHUB_TOKEN')
    success = update_recent_activity(username, token)
    if not success:
        exit(1)