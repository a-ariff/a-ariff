#!/usr/bin/env node

/**
 * README Updater Script
 * Updates the README.md with dynamic content while preserving static sections
 */

const fs = require('fs');
const path = require('path');

class ReadmeUpdater {
    constructor() {
        this.readmePath = '../README.md';
        this.activityFilePath = 'recent-activity.md';
    }

    readFile(filePath) {
        try {
            return fs.readFileSync(filePath, 'utf8');
        } catch (error) {
            console.error(`Error reading ${filePath}:`, error.message);
            return '';
        }
    }

    writeFile(filePath, content) {
        try {
            fs.writeFileSync(filePath, content, 'utf8');
            console.log(`Successfully updated ${filePath}`);
        } catch (error) {
            console.error(`Error writing ${filePath}:`, error.message);
        }
    }

    updateActivitySection(readmeContent, activityContent) {
        const startMarker = '<!-- ACTIVITY:START -->';
        const endMarker = '<!-- ACTIVITY:END -->';
        
        const startIndex = readmeContent.indexOf(startMarker);
        const endIndex = readmeContent.indexOf(endMarker);
        
        if (startIndex === -1 || endIndex === -1) {
            console.log('Activity markers not found. Adding activity section before GitHub Statistics.');
            
            // Find GitHub Statistics section to insert before it
            const statsMarker = '## 📈 **GitHub Statistics**';
            const statsIndex = readmeContent.indexOf(statsMarker);
            
            if (statsIndex !== -1) {
                const beforeStats = readmeContent.substring(0, statsIndex);
                const afterStats = readmeContent.substring(statsIndex);
                
                return `${beforeStats}## 🚀 **Recent Activity**

${activityContent}

---

${afterStats}`;
            } else {
                // Fallback: add at the end before the last section
                return readmeContent + '\n\n---\n\n## 🚀 **Recent Activity**\n\n' + activityContent + '\n';
            }
        }
        
        // Replace existing activity section
        const beforeActivity = readmeContent.substring(0, startIndex);
        const afterActivity = readmeContent.substring(endIndex + endMarker.length);
        
        return beforeActivity + activityContent + afterActivity;
    }

    updateBadges(readmeContent) {
        // Update visitor badge with more reliable endpoint
        const oldVisitorBadge = /!\[Profile Views\]\(https:\/\/komarev\.com\/ghpvc\/\?username=a-ariff[^)]*\)/g;
        const newVisitorBadge = '![Profile Views](https://komarev.com/ghpvc/?username=a-ariff&label=Profile%20views&color=0e75b6&style=for-the-badge)';
        
        readmeContent = readmeContent.replace(oldVisitorBadge, newVisitorBadge);

        // Ensure GitHub stats use reliable endpoints
        const statsPattern = /!\[.*?\]\(https:\/\/github-readme-stats\.vercel\.app\/api[^)]*\)/g;
        readmeContent = readmeContent.replace(
            /!\[(.*?)\]\(https:\/\/github-readme-stats\.vercel\.app\/api\?username=a-ariff[^)]*\)/g,
            '![GitHub Stats](https://github-readme-stats.vercel.app/api?username=a-ariff&show_icons=true&theme=tokyonight&include_all_commits=true&count_private=true&cache_seconds=86400)'
        );
        
        readmeContent = readmeContent.replace(
            /!\[(.*?)\]\(https:\/\/github-readme-stats\.vercel\.app\/api\/top-langs[^)]*\)/g,
            '![Top Languages](https://github-readme-stats.vercel.app/api/top-langs/?username=a-ariff&layout=compact&langs_count=8&theme=tokyonight&cache_seconds=86400)'
        );

        return readmeContent;
    }

    updateStreakStats(readmeContent) {
        // Update streak stats with cache
        const streakPattern = /!\[.*?\]\(https:\/\/streak-stats\.demolab\.com[^)]*\)/g;
        readmeContent = readmeContent.replace(
            streakPattern,
            '![GitHub Streak](https://streak-stats.demolab.com/?user=a-ariff&theme=tokyonight&cache_seconds=86400)'
        );

        return readmeContent;
    }

    async updateReadme() {
        console.log('Starting README update...');
        
        let readmeContent = this.readFile(this.readmePath);
        if (!readmeContent) {
            console.error('Failed to read README.md');
            return;
        }

        // Update badges for better reliability and caching
        readmeContent = this.updateBadges(readmeContent);
        readmeContent = this.updateStreakStats(readmeContent);

        // Update activity section if activity data exists
        const activityContent = this.readFile(this.activityFilePath);
        if (activityContent) {
            readmeContent = this.updateActivitySection(readmeContent, activityContent);
        }

        // Add timestamp to indicate last update
        const timestamp = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
        const timestampComment = `<!-- Last updated: ${timestamp} -->`;
        
        // Add timestamp at the top if not exists, or update existing
        if (readmeContent.includes('<!-- Last updated:')) {
            readmeContent = readmeContent.replace(/<!-- Last updated: .* -->/g, timestampComment);
        } else {
            readmeContent = timestampComment + '\n' + readmeContent;
        }

        this.writeFile(this.readmePath, readmeContent);
        
        console.log('README update completed successfully!');
    }
}

// Main execution
async function main() {
    const updater = new ReadmeUpdater();
    await updater.updateReadme();
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = ReadmeUpdater;