#!/usr/bin/env python3
"""
Advanced Threat Intelligence Collector
A comprehensive tool for gathering and analyzing threat intelligence from multiple sources.

Author: Ariff Mohamed
License: MIT
Version: 1.0.0
"""

import requests
import json
import csv
import hashlib
import ipaddress
import re
import time
import sqlite3
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from urllib.parse import urlparse
import os
import argparse

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class ThreatIndicator:
    """Data class for threat indicators"""
    value: str
    type: str  # ip, domain, hash, url
    source: str
    confidence: int  # 1-100
    tags: List[str]
    first_seen: datetime
    last_seen: datetime
    description: str = ""

class ThreatIntelligenceCollector:
    """Main threat intelligence collection and analysis class"""
    
    def __init__(self, config_file: str = "threat_intel_config.json"):
        """Initialize the threat intelligence collector"""
        self.config = self.load_config(config_file)
        self.db_file = self.config.get('database', 'threat_intelligence.db')
        self.api_keys = self.config.get('api_keys', {})
        self.init_database()
        
    def load_config(self, config_file: str) -> Dict[str, Any]:
        """Load configuration from file"""
        default_config = {
            "database": "threat_intelligence.db",
            "api_keys": {
                "virustotal": os.getenv("VT_API_KEY", ""),
                "alienvault": os.getenv("OTX_API_KEY", ""),
                "abuse_ch": os.getenv("ABUSE_CH_API_KEY", ""),
                "shodan": os.getenv("SHODAN_API_KEY", "")
            },
            "sources": {
                "virustotal": True,
                "alienvault_otx": True,
                "abuse_ch": True,
                "shodan": True,
                "threat_feeds": True
            },
            "collection_intervals": {
                "daily": ["threat_feeds", "cve_updates"],
                "hourly": ["high_priority_iocs"],
                "weekly": ["comprehensive_scan"]
            }
        }
        
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    user_config = json.load(f)
                    default_config.update(user_config)
            except Exception as e:
                logger.warning(f"Could not load config file: {e}")
        
        return default_config
    
    def init_database(self):
        """Initialize SQLite database for threat intelligence storage"""
        conn = sqlite3.connect(self.db_file)
        cursor = conn.cursor()
        
        # Create tables
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS threat_indicators (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                value TEXT UNIQUE NOT NULL,
                type TEXT NOT NULL,
                source TEXT NOT NULL,
                confidence INTEGER NOT NULL,
                tags TEXT,
                first_seen TIMESTAMP,
                last_seen TIMESTAMP,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS threat_campaigns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                description TEXT,
                threat_actor TEXT,
                tactics TEXT,
                techniques TEXT,
                first_seen TIMESTAMP,
                last_seen TIMESTAMP,
                indicators TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS vulnerability_intel (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                cve_id TEXT UNIQUE NOT NULL,
                cvss_score REAL,
                severity TEXT,
                description TEXT,
                published_date TIMESTAMP,
                exploited_in_wild BOOLEAN,
                patch_available BOOLEAN,
                affected_products TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
        logger.info("Database initialized successfully")
    
    def collect_virustotal_intelligence(self, indicator: str, indicator_type: str) -> Optional[ThreatIndicator]:
        """Collect threat intelligence from VirusTotal"""
        if not self.api_keys.get('virustotal'):
            logger.warning("VirusTotal API key not configured")
            return None
            
        headers = {'x-apikey': self.api_keys['virustotal']}
        
        try:
            if indicator_type == 'ip':
                url = f"https://www.virustotal.com/vtapi/v2/ip-address/report"
                params = {'apikey': self.api_keys['virustotal'], 'ip': indicator}
            elif indicator_type == 'domain':
                url = f"https://www.virustotal.com/vtapi/v2/domain/report"
                params = {'apikey': self.api_keys['virustotal'], 'domain': indicator}
            elif indicator_type == 'hash':
                url = f"https://www.virustotal.com/vtapi/v2/file/report"
                params = {'apikey': self.api_keys['virustotal'], 'resource': indicator}
            else:
                return None
            
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if data.get('response_code') == 1:
                positives = data.get('positives', 0)
                total = data.get('total', 1)
                confidence = int((positives / total) * 100) if total > 0 else 0
                
                return ThreatIndicator(
                    value=indicator,
                    type=indicator_type,
                    source="VirusTotal",
                    confidence=confidence,
                    tags=data.get('scans', {}).keys() if 'scans' in data else [],
                    first_seen=datetime.now(),
                    last_seen=datetime.now(),
                    description=f"Detected by {positives}/{total} engines"
                )
        
        except Exception as e:
            logger.error(f"Error collecting VirusTotal intelligence: {e}")
        
        return None
    
    def collect_alienvault_otx_intelligence(self, indicator: str, indicator_type: str) -> List[ThreatIndicator]:
        """Collect threat intelligence from AlienVault OTX"""
        if not self.api_keys.get('alienvault'):
            logger.warning("AlienVault OTX API key not configured")
            return []
        
        headers = {'X-OTX-API-KEY': self.api_keys['alienvault']}
        indicators = []
        
        try:
            if indicator_type == 'ip':
                url = f"https://otx.alienvault.com/api/v1/indicators/IPv4/{indicator}/general"
            elif indicator_type == 'domain':
                url = f"https://otx.alienvault.com/api/v1/indicators/domain/{indicator}/general"
            elif indicator_type == 'hash':
                url = f"https://otx.alienvault.com/api/v1/indicators/file/{indicator}/general"
            else:
                return []
            
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if data.get('pulse_info', {}).get('count', 0) > 0:
                pulse_count = data['pulse_info']['count']
                confidence = min(pulse_count * 10, 100)  # Scale pulse count to confidence
                
                indicator_obj = ThreatIndicator(
                    value=indicator,
                    type=indicator_type,
                    source="AlienVault OTX",
                    confidence=confidence,
                    tags=[pulse['name'] for pulse in data['pulse_info'].get('pulses', [])[:5]],
                    first_seen=datetime.now(),
                    last_seen=datetime.now(),
                    description=f"Found in {pulse_count} threat intelligence pulses"
                )
                indicators.append(indicator_obj)
        
        except Exception as e:
            logger.error(f"Error collecting AlienVault OTX intelligence: {e}")
        
        return indicators
    
    def collect_abuse_ch_intelligence(self) -> List[ThreatIndicator]:
        """Collect threat intelligence from Abuse.ch feeds"""
        indicators = []
        feeds = [
            {"url": "https://feodotracker.abuse.ch/downloads/ipblocklist.csv", "type": "ip"},
            {"url": "https://urlhaus.abuse.ch/downloads/csv_recent/", "type": "url"},
            {"url": "https://bazaar.abuse.ch/export/csv/recent/", "type": "hash"}
        ]
        
        for feed in feeds:
            try:
                response = requests.get(feed["url"], timeout=30)
                response.raise_for_status()
                
                if feed["type"] == "ip":
                    lines = response.text.strip().split('\n')
                    for line in lines[1:]:  # Skip header
                        if line and not line.startswith('#'):
                            parts = line.split(',')
                            if len(parts) >= 2:
                                ip = parts[0].strip('"')
                                description = parts[1].strip('"') if len(parts) > 1 else ""
                                
                                indicator = ThreatIndicator(
                                    value=ip,
                                    type="ip",
                                    source="Abuse.ch Feodo Tracker",
                                    confidence=85,
                                    tags=["malware", "botnet"],
                                    first_seen=datetime.now(),
                                    last_seen=datetime.now(),
                                    description=description
                                )
                                indicators.append(indicator)
                
                elif feed["type"] == "url":
                    lines = response.text.strip().split('\n')
                    for line in lines[1:]:  # Skip header
                        if line and not line.startswith('#'):
                            parts = line.split(',')
                            if len(parts) >= 3:
                                url = parts[2].strip('"')
                                status = parts[3].strip('"') if len(parts) > 3 else ""
                                
                                if status == "online":
                                    indicator = ThreatIndicator(
                                        value=url,
                                        type="url",
                                        source="Abuse.ch URLhaus",
                                        confidence=90,
                                        tags=["malware", "malicious_url"],
                                        first_seen=datetime.now(),
                                        last_seen=datetime.now(),
                                        description="Active malicious URL"
                                    )
                                    indicators.append(indicator)
            
            except Exception as e:
                logger.error(f"Error collecting from {feed['url']}: {e}")
        
        return indicators
    
    def collect_shodan_intelligence(self, ip: str) -> Optional[ThreatIndicator]:
        """Collect intelligence from Shodan for IP addresses"""
        if not self.api_keys.get('shodan'):
            logger.warning("Shodan API key not configured")
            return None
        
        try:
            url = f"https://api.shodan.io/shodan/host/{ip}"
            params = {'key': self.api_keys['shodan']}
            
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            # Analyze Shodan data for suspicious indicators
            suspicious_ports = [22, 23, 445, 3389, 5432, 3306]  # Common attack vectors
            open_ports = [str(service.get('port', 0)) for service in data.get('data', [])]
            suspicious_found = [port for port in open_ports if int(port) in suspicious_ports]
            
            confidence = len(suspicious_found) * 20  # Base confidence on suspicious ports
            if data.get('vulns'):
                confidence += 30  # Increase if vulnerabilities found
            
            tags = ['shodan', 'reconnaissance']
            if suspicious_found:
                tags.append('suspicious_ports')
            if data.get('vulns'):
                tags.append('vulnerable')
            
            return ThreatIndicator(
                value=ip,
                type="ip",
                source="Shodan",
                confidence=min(confidence, 100),
                tags=tags,
                first_seen=datetime.now(),
                last_seen=datetime.now(),
                description=f"Open ports: {', '.join(open_ports[:10])}"
            )
        
        except Exception as e:
            logger.error(f"Error collecting Shodan intelligence: {e}")
        
        return None
    
    def store_indicator(self, indicator: ThreatIndicator):
        """Store threat indicator in database"""
        conn = sqlite3.connect(self.db_file)
        cursor = conn.cursor()
        
        try:
            cursor.execute('''
                INSERT OR REPLACE INTO threat_indicators 
                (value, type, source, confidence, tags, first_seen, last_seen, description)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                indicator.value,
                indicator.type,
                indicator.source,
                indicator.confidence,
                ','.join(indicator.tags),
                indicator.first_seen,
                indicator.last_seen,
                indicator.description
            ))
            conn.commit()
            logger.info(f"Stored indicator: {indicator.value} from {indicator.source}")
        
        except Exception as e:
            logger.error(f"Error storing indicator: {e}")
        
        finally:
            conn.close()
    
    def analyze_indicators(self, indicators: List[str], indicator_type: str) -> Dict[str, Any]:
        """Analyze a list of indicators across multiple sources"""
        results = {
            'analyzed_count': len(indicators),
            'malicious_count': 0,
            'suspicious_count': 0,
            'clean_count': 0,
            'indicators': []
        }
        
        for indicator in indicators:
            logger.info(f"Analyzing {indicator_type}: {indicator}")
            
            # Collect from multiple sources
            threat_indicators = []
            
            # VirusTotal
            vt_result = self.collect_virustotal_intelligence(indicator, indicator_type)
            if vt_result:
                threat_indicators.append(vt_result)
            
            # AlienVault OTX
            otx_results = self.collect_alienvault_otx_intelligence(indicator, indicator_type)
            threat_indicators.extend(otx_results)
            
            # Shodan (for IPs only)
            if indicator_type == 'ip':
                shodan_result = self.collect_shodan_intelligence(indicator)
                if shodan_result:
                    threat_indicators.append(shodan_result)
            
            # Analyze combined results
            if threat_indicators:
                avg_confidence = sum(ti.confidence for ti in threat_indicators) / len(threat_indicators)
                max_confidence = max(ti.confidence for ti in threat_indicators)
                
                # Classify based on confidence levels
                if max_confidence >= 80:
                    classification = 'malicious'
                    results['malicious_count'] += 1
                elif max_confidence >= 50:
                    classification = 'suspicious'
                    results['suspicious_count'] += 1
                else:
                    classification = 'clean'
                    results['clean_count'] += 1
                
                indicator_result = {
                    'value': indicator,
                    'classification': classification,
                    'confidence': max_confidence,
                    'avg_confidence': avg_confidence,
                    'sources': [ti.source for ti in threat_indicators],
                    'tags': list(set(tag for ti in threat_indicators for tag in ti.tags))
                }
                
                results['indicators'].append(indicator_result)
                
                # Store all indicators
                for ti in threat_indicators:
                    self.store_indicator(ti)
            else:
                results['clean_count'] += 1
                results['indicators'].append({
                    'value': indicator,
                    'classification': 'clean',
                    'confidence': 0,
                    'sources': [],
                    'tags': []
                })
            
            # Rate limiting
            time.sleep(1)
        
        return results
    
    def generate_threat_report(self, analysis_results: Dict[str, Any]) -> str:
        """Generate a comprehensive threat intelligence report"""
        
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
        
        report = f"""
# 🔍 Threat Intelligence Analysis Report

**Generated:** {timestamp}
**Framework:** Advanced Cybersecurity Automation Framework
**Analyst:** Automated TI Collector v1.0.0

## 📊 Executive Summary

- **Total Indicators Analyzed:** {analysis_results['analyzed_count']}
- **Malicious Indicators:** {analysis_results['malicious_count']} ({analysis_results['malicious_count']/analysis_results['analyzed_count']*100:.1f}%)
- **Suspicious Indicators:** {analysis_results['suspicious_count']} ({analysis_results['suspicious_count']/analysis_results['analyzed_count']*100:.1f}%)
- **Clean Indicators:** {analysis_results['clean_count']} ({analysis_results['clean_count']/analysis_results['analyzed_count']*100:.1f}%)

## 🚨 High Priority Threats

"""
        
        # Add high priority threats
        high_priority = [ind for ind in analysis_results['indicators'] 
                        if ind['classification'] == 'malicious' and ind['confidence'] >= 90]
        
        if high_priority:
            for indicator in high_priority:
                report += f"- **{indicator['value']}** (Confidence: {indicator['confidence']}%)\n"
                report += f"  - Sources: {', '.join(indicator['sources'])}\n"
                report += f"  - Tags: {', '.join(indicator['tags'][:5])}\n\n"
        else:
            report += "No high-priority threats identified.\n\n"
        
        report += """
## 📈 Analysis Breakdown

| Classification | Count | Percentage |
|----------------|-------|------------|
"""
        
        total = analysis_results['analyzed_count']
        report += f"| Malicious | {analysis_results['malicious_count']} | {analysis_results['malicious_count']/total*100:.1f}% |\n"
        report += f"| Suspicious | {analysis_results['suspicious_count']} | {analysis_results['suspicious_count']/total*100:.1f}% |\n"
        report += f"| Clean | {analysis_results['clean_count']} | {analysis_results['clean_count']/total*100:.1f}% |\n\n"
        
        report += """
## 🔬 Detailed Findings

"""
        
        for indicator in analysis_results['indicators']:
            if indicator['classification'] in ['malicious', 'suspicious']:
                report += f"### {indicator['value']}\n"
                report += f"- **Classification:** {indicator['classification'].upper()}\n"
                report += f"- **Confidence:** {indicator['confidence']}%\n"
                report += f"- **Sources:** {', '.join(indicator['sources'])}\n"
                report += f"- **Tags:** {', '.join(indicator['tags'])}\n\n"
        
        report += """
## 💡 Recommendations

1. **Immediate Actions:**
   - Block all malicious indicators in security controls
   - Monitor suspicious indicators closely
   - Update threat hunting rules

2. **Strategic Actions:**
   - Review security policies for gaps
   - Enhance detection capabilities
   - Conduct threat hunting exercises

3. **Follow-up:**
   - Schedule re-analysis in 24-48 hours
   - Monitor for new IOCs related to campaigns
   - Share intelligence with security team

---
*Report generated by Advanced Cybersecurity Automation Framework*
"""
        
        return report

def main():
    """Main execution function"""
    parser = argparse.ArgumentParser(description="Advanced Threat Intelligence Collector")
    parser.add_argument('-i', '--indicators', nargs='+', help="Indicators to analyze")
    parser.add_argument('-t', '--type', choices=['ip', 'domain', 'hash', 'url'], 
                       help="Type of indicators", required=False)
    parser.add_argument('-f', '--file', help="File containing indicators (one per line)")
    parser.add_argument('-o', '--output', help="Output file for report")
    parser.add_argument('--feeds', action='store_true', help="Collect from threat feeds")
    
    args = parser.parse_args()
    
    # Initialize collector
    collector = ThreatIntelligenceCollector()
    
    if args.feeds:
        logger.info("Collecting from threat feeds...")
        indicators = collector.collect_abuse_ch_intelligence()
        for indicator in indicators:
            collector.store_indicator(indicator)
        logger.info(f"Collected {len(indicators)} indicators from threat feeds")
        return
    
    if args.file:
        with open(args.file, 'r') as f:
            indicators = [line.strip() for line in f if line.strip()]
    elif args.indicators:
        indicators = args.indicators
    else:
        logger.error("Please provide indicators via -i or -f options")
        return
    
    # Auto-detect indicator type if not specified
    if not args.type and indicators:
        sample = indicators[0]
        try:
            ipaddress.ip_address(sample)
            indicator_type = 'ip'
        except:
            if '.' in sample and len(sample.split('.')) >= 2:
                indicator_type = 'domain'
            elif len(sample) in [32, 40, 64]:  # Common hash lengths
                indicator_type = 'hash'
            else:
                indicator_type = 'url'
    else:
        indicator_type = args.type
    
    logger.info(f"Analyzing {len(indicators)} {indicator_type} indicators...")
    
    # Perform analysis
    results = collector.analyze_indicators(indicators, indicator_type)
    
    # Generate report
    report = collector.generate_threat_report(results)
    
    if args.output:
        with open(args.output, 'w') as f:
            f.write(report)
        logger.info(f"Report saved to {args.output}")
    else:
        print(report)

if __name__ == "__main__":
    main()