#!/usr/bin/env node

/**
 * Fetch Recent Activity Script
 * Fetches recent repository activity and blog posts for GitHub profile README
 */

const https = require('https');
const fs = require('fs');

class ActivityFetcher {
    constructor() {
        this.username = 'a-ariff';
        this.maxRepos = 5;
        this.maxBlogPosts = 5;
    }

    async makeRequest(url, headers = {}) {
        return new Promise((resolve, reject) => {
            const options = {
                headers: {
                    'User-Agent': 'GitHub-Profile-README-Updater',
                    ...headers
                }
            };

            https.get(url, options, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        resolve(data);
                    }
                });
            }).on('error', reject);
        });
    }

    async fetchRecentRepos() {
        try {
            const url = `https://api.github.com/users/${this.username}/repos?sort=updated&per_page=${this.maxRepos}&type=owner`;
            const repos = await this.makeRequest(url);
            
            if (!Array.isArray(repos)) {
                console.error('API response is not an array:', repos);
                return [];
            }
            
            return repos.map(repo => ({
                name: repo.name,
                description: repo.description || 'No description available',
                url: repo.html_url,
                language: repo.language,
                updated_at: repo.updated_at,
                topics: repo.topics || []
            }));
        } catch (error) {
            console.error('Error fetching repos:', error.message);
            return [];
        }
    }

    async fetchBlogPosts() {
        // Since we don't have a specific blog URL, this will return empty array
        // This provides graceful fallback as required
        try {
            // Placeholder for blog posts - could be implemented with RSS feeds if available
            console.log('Blog posts feature not configured - using graceful fallback');
            return [];
        } catch (error) {
            console.error('Error fetching blog posts:', error.message);
            return [];
        }
    }

    formatRepoSection(repos) {
        if (repos.length === 0) {
            return '<!-- No recent repositories -->';
        }

        let markdown = '### 📊 Recent Repository Activity\n\n';
        
        repos.forEach(repo => {
            const updatedDate = new Date(repo.updated_at).toLocaleDateString();
            const languageBadge = repo.language ? 
                `![${repo.language}](https://img.shields.io/badge/-${repo.language}-blue?style=flat-square)` : '';
            
            markdown += `- **[${repo.name}](${repo.url})** ${languageBadge}\n`;
            markdown += `  ${repo.description}\n`;
            markdown += `  *Updated: ${updatedDate}*\n\n`;
        });

        return markdown;
    }

    formatBlogSection(posts) {
        if (posts.length === 0) {
            return '<!-- Blog posts will be displayed here when available -->';
        }

        let markdown = '### 📝 Latest Blog Posts\n\n';
        
        posts.forEach(post => {
            markdown += `- [${post.title}](${post.url})\n`;
            markdown += `  *${post.date}*\n\n`;
        });

        return markdown;
    }

    async generateActivityMarkdown() {
        console.log('Fetching recent repository activity...');
        const repos = await this.fetchRecentRepos();
        
        console.log('Checking for blog posts...');
        const posts = await this.fetchBlogPosts();

        const repoSection = this.formatRepoSection(repos);
        const blogSection = this.formatBlogSection(posts);

        const timestamp = new Date().toISOString();
        
        return `<!-- ACTIVITY:START -->
<!-- Last updated: ${timestamp} -->

${repoSection}

${blogSection}

<!-- ACTIVITY:END -->`;
    }
}

// Main execution
async function main() {
    const fetcher = new ActivityFetcher();
    const activityMarkdown = await fetcher.generateActivityMarkdown();
    
    // Write to file for GitHub Actions to use
    fs.writeFileSync('recent-activity.md', activityMarkdown);
    console.log('Activity data generated successfully!');
    console.log(activityMarkdown);
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = ActivityFetcher;