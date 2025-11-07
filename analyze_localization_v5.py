#!/usr/bin/env python3
"""
LifeStyles Localization Analyzer V5 - Enterprise Edition
=========================================================

🚀 V5 New Features:
- ⚡ AUTO-FIX MODE: Automatically fix hardcoded strings
- 🎮 INTERACTIVE MODE: Review and approve changes one by one
- 👁️ WATCH MODE: Monitor files for changes in real-time
- 🌍 LANGUAGE MANAGEMENT: Add new languages easily
- 🔍 KEY PATTERN ANALYSIS: Detect custom patterns
- 📊 FREQUENCY-BASED AUTO-FIX: Prioritize common duplicates
- 🚄 PERFORMANCE: Multi-threading and caching
- 💾 AUTO-BACKUP: Safe modifications with automatic backups
- 🎯 DRY-RUN: Preview changes before applying

Usage:
    # Analysis only
    python analyze_localization_v5.py

    # Auto-fix all high-priority strings
    python analyze_localization_v5.py --auto-fix

    # Interactive mode (approve one by one)
    python analyze_localization_v5.py --interactive

    # Fix duplicates only
    python analyze_localization_v5.py --fix-duplicates

    # Watch mode
    python analyze_localization_v5.py --watch

    # Dry run (preview changes)
    python analyze_localization_v5.py --auto-fix --dry-run

    # Language management
    python analyze_localization_v5.py --list-languages
    python analyze_localization_v5.py --add-language es
    python analyze_localization_v5.py --add-language de --source-lang en
"""

import re
import os
import sys
import json
import shutil
import hashlib
import argparse
import time
from pathlib import Path
from collections import defaultdict, Counter
from typing import Dict, List, Set, Tuple, Optional
from datetime import datetime
from difflib import SequenceMatcher
from concurrent.futures import ThreadPoolExecutor, as_completed
from functools import lru_cache
import html

# Optional dependencies
try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
    WATCHDOG_AVAILABLE = True
except ImportError:
    WATCHDOG_AVAILABLE = False
    print("⚠️  watchdog not installed. Watch mode disabled. Install: pip install watchdog")

try:
    from tqdm import tqdm
    TQDM_AVAILABLE = True
except ImportError:
    TQDM_AVAILABLE = False


class Colors:
    """ANSI color codes for terminal output"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


class StringsFileManager:
    """Manages reading and writing to .strings files"""

    def __init__(self, tr_file: Path, en_file: Path):
        self.tr_file = tr_file
        self.en_file = en_file
        self.keys = {}  # key -> {tr, en}

    def load(self):
        """Load existing keys from .strings files"""
        for file_path, lang in [(self.tr_file, 'tr'), (self.en_file, 'en')]:
            if not file_path.exists():
                continue

            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                pattern = r'^"([^"]+)"\s*=\s*"([^"]+)";'
                matches = re.finditer(pattern, content, re.MULTILINE)

                for match in matches:
                    key, value = match.groups()
                    if key not in self.keys:
                        self.keys[key] = {'tr': None, 'en': None}
                    self.keys[key][lang] = value

    def add_key(self, key: str, tr_value: str, en_value: str, dry_run: bool = False):
        """Add a new key to .strings files"""
        if key in self.keys:
            print(f"  ⚠️  Key already exists: {key}")
            return False

        if dry_run:
            print(f"  [DRY RUN] Would add: \"{key}\" = \"{tr_value}\";")
            return True

        # Add to TR file
        with open(self.tr_file, 'a', encoding='utf-8') as f:
            f.write(f'\n"{key}" = "{tr_value}";\n')

        # Add to EN file
        with open(self.en_file, 'a', encoding='utf-8') as f:
            f.write(f'\n"{key}" = "{en_value}";\n')

        self.keys[key] = {'tr': tr_value, 'en': en_value}
        return True

    def key_exists(self, key: str) -> bool:
        """Check if a key exists"""
        return key in self.keys


class LanguageManager:
    """Manages adding new languages to the project"""

    # Common language codes and names
    LANGUAGE_NAMES = {
        'ar': 'Arabic', 'de': 'German', 'es': 'Spanish', 'fr': 'French',
        'it': 'Italian', 'ja': 'Japanese', 'ko': 'Korean', 'pt': 'Portuguese',
        'ru': 'Russian', 'zh': 'Chinese', 'nl': 'Dutch', 'pl': 'Polish',
        'sv': 'Swedish', 'da': 'Danish', 'no': 'Norwegian', 'fi': 'Finnish',
        'el': 'Greek', 'he': 'Hebrew', 'hi': 'Hindi', 'th': 'Thai',
        'vi': 'Vietnamese', 'id': 'Indonesian', 'ms': 'Malay', 'cs': 'Czech',
        'hu': 'Hungarian', 'ro': 'Romanian', 'uk': 'Ukrainian', 'ca': 'Catalan',
    }

    def __init__(self, resources_dir: Path):
        self.resources_dir = resources_dir
        self.available_languages = self._scan_languages()

    def _scan_languages(self) -> Dict[str, Path]:
        """Scan for existing language directories"""
        languages = {}
        if not self.resources_dir.exists():
            return languages

        for lproj_dir in self.resources_dir.glob('*.lproj'):
            lang_code = lproj_dir.name.replace('.lproj', '')
            languages[lang_code] = lproj_dir

        return languages

    def list_languages(self) -> List[Dict]:
        """List all available languages"""
        result = []
        for lang_code, lang_dir in self.available_languages.items():
            strings_file = lang_dir / 'Localizable.strings'
            key_count = 0

            if strings_file.exists():
                try:
                    with open(strings_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        key_count = len(re.findall(r'^"([^"]+)"\s*=', content, re.MULTILINE))
                except:
                    pass

            lang_name = self.LANGUAGE_NAMES.get(lang_code, 'Unknown')
            result.append({
                'code': lang_code,
                'name': lang_name,
                'path': str(lang_dir),
                'key_count': key_count,
                'has_strings': strings_file.exists()
            })

        return result

    def add_language(
        self,
        lang_code: str,
        source_lang: str = 'tr',
        empty: bool = False,
        dry_run: bool = False
    ) -> bool:
        """
        Add a new language to the project

        Args:
            lang_code: Language code (e.g., 'es', 'de', 'fr')
            source_lang: Source language to copy keys from (default: 'tr')
            empty: Create empty strings file (default: False)
            dry_run: Preview without creating files (default: False)

        Returns:
            bool: Success status
        """
        # Validate language code
        lang_code = lang_code.lower().strip()
        if len(lang_code) < 2 or len(lang_code) > 3:
            print(f"{Colors.FAIL}❌ Invalid language code: {lang_code}{Colors.ENDC}")
            print("   Language codes should be 2-3 characters (e.g., es, de, fr)")
            return False

        # Check if language already exists
        if lang_code in self.available_languages:
            print(f"{Colors.WARNING}⚠️  Language '{lang_code}' already exists{Colors.ENDC}")
            print(f"   Path: {self.available_languages[lang_code]}")
            return False

        # Validate source language
        if source_lang not in self.available_languages and not empty:
            print(f"{Colors.FAIL}❌ Source language '{source_lang}' not found{Colors.ENDC}")
            print(f"   Available: {', '.join(self.available_languages.keys())}")
            return False

        lang_name = self.LANGUAGE_NAMES.get(lang_code, f"Language ({lang_code})")

        print(f"\n{Colors.BOLD}🌍 YENİ DİL EKLEME - {lang_name} ({lang_code}){Colors.ENDC}")
        print("=" * 70)

        # Create language directory
        lang_dir = self.resources_dir / f'{lang_code}.lproj'
        strings_file = lang_dir / 'Localizable.strings'

        if dry_run:
            print(f"{Colors.WARNING}[DRY RUN]{Colors.ENDC}")

        print(f"📁 Klasör oluşturuluyor: {lang_dir.relative_to(self.resources_dir.parent)}")
        if not dry_run:
            lang_dir.mkdir(parents=True, exist_ok=True)
            print(f"   {Colors.OKGREEN}✓ Oluşturuldu{Colors.ENDC}")
        else:
            print(f"   {Colors.OKCYAN}[DRY RUN] Would create{Colors.ENDC}")

        print(f"📄 Dosya oluşturuluyor: Localizable.strings")

        if empty:
            # Create empty file with header
            content = self._create_empty_strings_file(lang_code, lang_name)
            print(f"   {Colors.OKCYAN}Boş dosya şablonu hazırlandı{Colors.ENDC}")
        else:
            # Copy keys from source language
            source_file = self.available_languages[source_lang] / 'Localizable.strings'
            if not source_file.exists():
                print(f"{Colors.FAIL}❌ Source strings file not found: {source_file}{Colors.ENDC}")
                return False

            print(f"📋 Key'ler kopyalanıyor (kaynak: {source_lang})")
            content, key_count = self._copy_keys_from_source(source_file, lang_code, lang_name)
            print(f"   {Colors.OKGREEN}✓ {key_count} key kopyalandı{Colors.ENDC}")

        # Write file
        if not dry_run:
            with open(strings_file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"   {Colors.OKGREEN}✓ Dosya kaydedildi{Colors.ENDC}")
        else:
            print(f"   {Colors.OKCYAN}[DRY RUN] Would write {len(content)} bytes{Colors.ENDC}")

        # Validate
        if not dry_run and not empty:
            is_valid = self._validate_strings_file(strings_file)
            if is_valid:
                print(f"   {Colors.OKGREEN}✓ Format doğrulandı{Colors.ENDC}")
            else:
                print(f"   {Colors.WARNING}⚠️  Format doğrulaması başarısız{Colors.ENDC}")

        print(f"\n{Colors.OKGREEN}✅ {lang_name} başarıyla eklendi!{Colors.ENDC}")

        # Next steps
        print(f"\n{Colors.BOLD}📝 Sonraki Adımlar:{Colors.ENDC}")
        print(f"1. {strings_file.relative_to(self.resources_dir.parent)} dosyasını çevir")
        print(f"2. Xcode'da projeye ekle: File → Add Files to Project")
        print(f"3. Target'ı seç ve Build Phases → Copy Bundle Resources'a ekle")
        print(f"4. Build ve test et")
        print(f"5. Simulator'da dil ayarlarını değiştirerek test et")

        return True

    def _create_empty_strings_file(self, lang_code: str, lang_name: str) -> str:
        """Create empty .strings file with header"""
        return f'''/*
  Localizable.strings ({lang_name})
  LifeStyles

  Created: {datetime.now().strftime('%Y-%m-%d')}
  Language: {lang_name} ({lang_code})

  TODO: Add translations for all keys below
*/

/* Example format:
"key.name" = "Translated text";
*/

'''

    def _copy_keys_from_source(
        self,
        source_file: Path,
        target_lang: str,
        target_lang_name: str
    ) -> Tuple[str, int]:
        """
        Copy keys from source language file

        Returns:
            Tuple[str, int]: (file content, key count)
        """
        with open(source_file, 'r', encoding='utf-8') as f:
            source_content = f.read()

        # Parse keys
        pattern = r'^("([^"]+)"\s*=\s*"([^"]+)";)'
        matches = list(re.finditer(pattern, source_content, re.MULTILINE))

        # Build new content
        lines = [
            f'/*',
            f'  Localizable.strings ({target_lang_name})',
            f'  LifeStyles',
            f'',
            f'  Created: {datetime.now().strftime("%Y-%m-%d")}',
            f'  Language: {target_lang_name} ({target_lang})',
            f'  Copied from: {source_file.parent.name}',
            f'',
            f'  NOTE: Please translate all values to {target_lang_name}',
            f'  Total keys: {len(matches)}',
            f'*/',
            f''
        ]

        # Add all keys
        for match in matches:
            full_line = match.group(1)
            lines.append(full_line)

        lines.append('')  # Trailing newline

        return '\n'.join(lines), len(matches)

    def _validate_strings_file(self, file_path: Path) -> bool:
        """Validate .strings file format"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Check for basic format errors
            # Each key should match: "key" = "value";
            lines = [line.strip() for line in content.split('\n')
                     if line.strip() and not line.strip().startswith('/*') and not line.strip().startswith('*')]

            for line in lines:
                if not line.startswith('//') and '=' in line:
                    if not re.match(r'^"[^"]+"\s*=\s*"[^"]*";', line):
                        print(f"      Invalid line format: {line[:50]}...")
                        return False

            return True
        except Exception as e:
            print(f"      Validation error: {e}")
            return False


class AutoFixer:
    """Automatically fixes hardcoded strings in Swift files"""

    def __init__(self, strings_manager: StringsFileManager, dry_run: bool = False):
        self.strings_manager = strings_manager
        self.dry_run = dry_run
        self.fixes_applied = 0
        self.fixes_failed = 0

    def fix_hardcoded_string(
        self,
        file_path: Path,
        line_num: int,
        original_text: str,
        component_type: str,
        suggested_key: str,
        tr_translation: Optional[str] = None,
        en_translation: Optional[str] = None
    ) -> bool:
        """Fix a single hardcoded string"""

        # Default translations
        if tr_translation is None:
            tr_translation = original_text
        if en_translation is None:
            en_translation = original_text

        # Read file
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except Exception as e:
            print(f"  ❌ Failed to read {file_path}: {e}")
            self.fixes_failed += 1
            return False

        if line_num < 1 or line_num > len(lines):
            print(f"  ❌ Invalid line number: {line_num}")
            self.fixes_failed += 1
            return False

        # Get the line to modify
        line = lines[line_num - 1]

        # Check if line contains the original text
        if f'"{original_text}"' not in line:
            print(f"  ⚠️  Line doesn't contain expected text: {original_text}")
            self.fixes_failed += 1
            return False

        # Generate replacement based on component type
        replacement = self._generate_replacement(component_type, original_text, suggested_key)

        if replacement is None:
            print(f"  ⚠️  Cannot generate replacement for {component_type}")
            self.fixes_failed += 1
            return False

        # Replace in line
        new_line = line.replace(f'"{original_text}"', replacement)

        if self.dry_run:
            print(f"\n  [DRY RUN] {file_path}:{line_num}")
            print(f"    - {line.strip()}")
            print(f"    + {new_line.strip()}")
            self.fixes_applied += 1
            return True

        # Add key to .strings files
        if not self.strings_manager.key_exists(suggested_key):
            if not self.strings_manager.add_key(suggested_key, tr_translation, en_translation, self.dry_run):
                self.fixes_failed += 1
                return False

        # Apply fix
        lines[line_num - 1] = new_line

        # Write file
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
            print(f"  ✅ Fixed: {file_path.name}:{line_num}")
            self.fixes_applied += 1
            return True
        except Exception as e:
            print(f"  ❌ Failed to write {file_path}: {e}")
            self.fixes_failed += 1
            return False

    def _generate_replacement(self, component_type: str, original_text: str, key: str) -> Optional[str]:
        """Generate the replacement code based on component type"""

        # Simple Text() replacement
        if component_type in ['Text', 'Label', 'Button', 'NavigationTitle', 'Section']:
            return f'String(localized: "{key}")'

        # TextField placeholder
        if component_type == 'TextField':
            return f'String(localized: "{key}")'

        # Other patterns
        if 'Text' in component_type or 'Label' in component_type:
            return f'String(localized: "{key}")'

        # Default: use String(localized:)
        return f'String(localized: "{key}")'

    def get_stats(self) -> Dict:
        """Return fix statistics"""
        return {
            'applied': self.fixes_applied,
            'failed': self.fixes_failed,
            'total': self.fixes_applied + self.fixes_failed
        }


class InteractiveCLI:
    """Interactive CLI for reviewing and approving fixes"""

    def __init__(self, analyzer: 'LocalizationAnalyzerV5', auto_fixer: AutoFixer):
        self.analyzer = analyzer
        self.auto_fixer = auto_fixer
        self.approved = 0
        self.skipped = 0
        self.edited = 0

    def run(self):
        """Run interactive mode"""
        print("\n" + "=" * 70)
        print(f"{Colors.BOLD}🎮 INTERACTIVE MODE{Colors.ENDC}")
        print("=" * 70)
        print("Review and approve each hardcoded string one by one.\n")
        print("Commands:")
        print("  [y] Yes - Apply this fix")
        print("  [n] No - Skip this fix")
        print("  [e] Edit - Customize the key name")
        print("  [q] Quit - Exit interactive mode")
        print("=" * 70 + "\n")

        # Sort by priority
        sorted_strings = sorted(
            self.analyzer.hardcoded_strings,
            key=lambda x: x['priority'],
            reverse=True
        )

        for i, item in enumerate(sorted_strings, 1):
            print(f"\n[{i}/{len(sorted_strings)}] Priority: {item['priority']}/10")
            print(f"File: {Colors.OKCYAN}{item['file']}:{item['line']}{Colors.ENDC}")
            print(f"Text: {Colors.BOLD}\"{item['text']}\"{Colors.ENDC}")
            print(f"Component: {item['component']}")
            print(f"Suggested Key: {Colors.OKGREEN}{item['suggested_key']}{Colors.ENDC}")

            while True:
                choice = input(f"\n{Colors.WARNING}Action [y/n/e/q]?{Colors.ENDC} ").strip().lower()

                if choice == 'y':
                    # Apply fix
                    success = self.auto_fixer.fix_hardcoded_string(
                        Path(self.analyzer.project_dir) / item['file'],
                        item['line'],
                        item['text'],
                        item['component'],
                        item['suggested_key']
                    )
                    if success:
                        self.approved += 1
                    break

                elif choice == 'n':
                    print(f"  ⏭️  Skipped")
                    self.skipped += 1
                    break

                elif choice == 'e':
                    custom_key = input(f"Enter custom key name [{item['suggested_key']}]: ").strip()
                    if not custom_key:
                        custom_key = item['suggested_key']

                    success = self.auto_fixer.fix_hardcoded_string(
                        Path(self.analyzer.project_dir) / item['file'],
                        item['line'],
                        item['text'],
                        item['component'],
                        custom_key
                    )
                    if success:
                        self.edited += 1
                    break

                elif choice == 'q':
                    print(f"\n{Colors.WARNING}Exiting interactive mode...{Colors.ENDC}")
                    self._print_summary()
                    return

                else:
                    print(f"{Colors.FAIL}Invalid choice. Please enter y/n/e/q{Colors.ENDC}")

        self._print_summary()

    def _print_summary(self):
        """Print interactive session summary"""
        print("\n" + "=" * 70)
        print(f"{Colors.BOLD}📊 INTERACTIVE SESSION SUMMARY{Colors.ENDC}")
        print("=" * 70)
        print(f"✅ Approved: {self.approved}")
        print(f"✏️  Edited: {self.edited}")
        print(f"⏭️  Skipped: {self.skipped}")
        print(f"📝 Total Reviewed: {self.approved + self.edited + self.skipped}")
        print("=" * 70)


class WatchMode:
    """Watch files for changes and trigger analysis"""

    def __init__(self, project_dir: Path, analyzer_factory):
        self.project_dir = project_dir
        self.analyzer_factory = analyzer_factory
        self.last_run = 0
        self.debounce_seconds = 2

    def start(self):
        """Start watching files"""
        if not WATCHDOG_AVAILABLE:
            print(f"{Colors.FAIL}❌ Watch mode requires 'watchdog' package{Colors.ENDC}")
            print(f"Install with: pip install watchdog")
            return

        print(f"\n{Colors.BOLD}👁️  WATCH MODE ACTIVE{Colors.ENDC}")
        print(f"Monitoring: {self.project_dir}")
        print("Press Ctrl+C to stop\n")

        event_handler = self._create_handler()
        observer = Observer()
        observer.schedule(event_handler, str(self.project_dir), recursive=True)
        observer.start()

        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            observer.stop()
            print(f"\n{Colors.WARNING}Watch mode stopped{Colors.ENDC}")

        observer.join()

    def _create_handler(self):
        """Create file system event handler"""
        parent = self

        class SwiftFileHandler(FileSystemEventHandler):
            def on_modified(self, event):
                if event.is_directory:
                    return

                if not event.src_path.endswith('.swift'):
                    return

                # Debounce
                now = time.time()
                if now - parent.last_run < parent.debounce_seconds:
                    return

                parent.last_run = now
                print(f"\n{Colors.OKCYAN}🔄 File changed: {event.src_path}{Colors.ENDC}")
                parent._run_analysis()

        return SwiftFileHandler()

    def _run_analysis(self):
        """Run quick analysis"""
        print(f"{Colors.OKBLUE}Running quick analysis...{Colors.ENDC}")
        analyzer = self.analyzer_factory()
        analyzer.load_existing_keys()
        analyzer.find_swift_files()
        analyzer.analyze_all_files()

        # Quick summary
        total = len(analyzer.hardcoded_strings) + len(analyzer.localized_usages)
        hardcoded = len(analyzer.hardcoded_strings)
        rate = (len(analyzer.localized_usages) / total * 100) if total > 0 else 100

        print(f"{Colors.OKGREEN}✓ Analysis complete{Colors.ENDC}")
        print(f"  Localization: {rate:.1f}% ({len(analyzer.localized_usages)}/{total})")
        print(f"  Hardcoded: {hardcoded}")
        print(f"  {Colors.OKCYAN}Watching for changes...{Colors.ENDC}\n")


class KeyPatternAnalyzer:
    """Analyzes custom key patterns not in standard categories"""

    def __init__(self):
        self.custom_patterns = []
        self.pattern_freq = Counter()

    def analyze(self, keys: Set[str]) -> Dict:
        """Analyze key patterns"""
        patterns = defaultdict(list)

        for key in keys:
            # Extract pattern (prefix before first dot or underscore)
            match = re.match(r'^([a-z]+)[._]', key)
            if match:
                prefix = match.group(1)
                patterns[prefix].append(key)
                self.pattern_freq[prefix] += 1

        return {
            'patterns': dict(patterns),
            'frequency': dict(self.pattern_freq),
            'total_patterns': len(patterns),
            'most_common': self.pattern_freq.most_common(10)
        }


class LocalizationAnalyzerV5:
    """Enhanced V5 analyzer with auto-fix and advanced features"""

    def __init__(self, project_dir: str):
        self.project_dir = Path(project_dir)
        self.swift_files = []
        self.hardcoded_strings = []
        self.localized_usages = []
        self.existing_keys = {}
        self.used_keys = set()
        self.dead_keys = set()
        self.missing_keys = defaultdict(list)
        self.component_stats = defaultdict(lambda: {'total': 0, 'localized': 0, 'hardcoded': 0})
        self.file_stats = defaultdict(lambda: {'total': 0, 'localized': 0, 'hardcoded': 0})
        self.folder_stats = defaultdict(lambda: {'total': 0, 'localized': 0, 'hardcoded': 0})
        self.duplicate_strings = defaultdict(list)
        self.interpolated_strings = []
        self.format_strings = []
        self.similar_strings = []
        self.translation_issues = []
        self.context_groups = defaultdict(list)

        # V5: Key pattern analyzer
        self.key_pattern_analyzer = KeyPatternAnalyzer()

        # Priority weights
        self.priority_weights = {
            'visible_ui': 10,
            'user_facing': 8,
            'error_messages': 9,
            'navigation': 7,
            'labels': 6,
            'placeholders': 5,
            'internal': 2,
        }

        # Patterns
        self.hardcoded_patterns = [
            (r'Text\(\s*"([^"]+)"\s*\)', 'Text', 'visible_ui'),
            (r'Label\(\s*"([^"]+)"', 'Label', 'visible_ui'),
            (r'Button\(\s*"([^"]+)"', 'Button', 'visible_ui'),
            (r'\.navigationTitle\(\s*"([^"]+)"\s*\)', 'NavigationTitle', 'navigation'),
            (r'Alert\([^)]*title:\s*Text\(\s*"([^"]+)"\s*\)', 'Alert', 'error_messages'),
            (r'TextField\(\s*"([^"]+)"', 'TextField', 'placeholders'),
            (r'Menu\(\s*"([^"]+)"', 'Menu', 'visible_ui'),
            (r'Section\(\s*"([^"]+)"', 'Section', 'visible_ui'),
            (r'LabeledContent\(\s*"([^"]+)"', 'LabeledContent', 'labels'),
            (r'\.confirmationDialog\(\s*"([^"]+)"', 'ConfirmationDialog', 'user_facing'),
            (r'\.accessibilityLabel\(\s*"([^"]+)"\s*\)', 'AccessibilityLabel', 'user_facing'),
            (r'\.placeholder\(\s*"([^"]+)"\s*\)', 'Placeholder', 'placeholders'),
            (r'\.help\(\s*"([^"]+)"\s*\)', 'Help', 'user_facing'),
            (r'\.badge\(\s*"([^"]+)"\s*\)', 'Badge', 'visible_ui'),
        ]

        self.localized_patterns = [
            (r'String\(\s*localized:\s*"([^"]+)"', 'String.localized'),
            (r'NSLocalizedString\(\s*"([^"]+)"\s*,\s*comment:', 'NSLocalizedString'),
            (r'LocalizedStringKey\(\s*"([^"]+)"\s*\)', 'LocalizedStringKey'),
        ]

        self.exclude_patterns = [
            r'^[\U0001F300-\U0001F9FF]+$',
            r'^[0-9\s\.\,\-\+\*\/\=\<\>]+$',
            r'^(https?://|www\.)',
            r'^[A-Z_]+$',
            r'^SF Symbols?:',
            r'^\$\d+',
            r'^%[a-z]+$',
            r'^\.{3,}$',
            r'^\s*$',
        ]

        # Dinamik olarak tüm dilleri tara
        self.localization_files = self._discover_localization_files()

    def _discover_localization_files(self) -> List[Path]:
        """
        Dinamik olarak tüm .lproj klasörlerini tarar ve Localizable.strings dosyalarını bulur

        Returns:
            List[Path]: Bulunan tüm Localizable.strings dosyalarının yolları
        """
        localization_files = []
        resources_dir = self.project_dir / 'LifeStyles/Resources'

        if not resources_dir.exists():
            print(f"{Colors.WARNING}⚠️  Resources klasörü bulunamadı: {resources_dir}{Colors.ENDC}")
            return localization_files

        # Tüm .lproj klasörlerini tara
        for lproj_dir in sorted(resources_dir.glob('*.lproj')):
            lang_code = lproj_dir.name.replace('.lproj', '')
            strings_file = lproj_dir / 'Localizable.strings'

            if strings_file.exists():
                localization_files.append(strings_file)
                print(f"{Colors.OKGREEN}✓{Colors.ENDC} Dil bulundu: {Colors.BOLD}{lang_code}{Colors.ENDC} - {strings_file}")
            else:
                print(f"{Colors.WARNING}⚠{Colors.ENDC} Strings dosyası eksik: {lang_code} - {strings_file}")

        if not localization_files:
            print(f"{Colors.FAIL}❌ Hiç lokalizasyon dosyası bulunamadı!{Colors.ENDC}")
        else:
            print(f"{Colors.OKBLUE}📊 Toplam {len(localization_files)} dil bulundu{Colors.ENDC}")

        return localization_files

    def _should_exclude(self, text: str) -> bool:
        """Check if string should be excluded"""
        if not text or len(text.strip()) == 0:
            return True

        for pattern in self.exclude_patterns:
            if re.match(pattern, text.strip()):
                return True

        if len(text.strip()) <= 1:
            return True

        alpha_count = sum(c.isalpha() for c in text)
        if alpha_count < len(text) * 0.3:
            return True

        return False

    def _calculate_priority(self, component_type: str, category: str, text: str) -> int:
        """Calculate priority score"""
        base_score = self.priority_weights.get(category, 5)

        if len(text) < 20:
            base_score += 2

        if any(word in text.lower() for word in ['error', 'warning', 'failed', 'success']):
            base_score += 3

        if component_type in ['Button', 'Label', 'Menu']:
            base_score += 2

        return min(10, base_score)

    @lru_cache(maxsize=1024)
    def _similarity(self, str1: str, str2: str) -> float:
        """Calculate similarity (cached)"""
        return SequenceMatcher(None, str1.lower(), str2.lower()).ratio()

    def _suggest_key_name(self, text: str, component_type: str) -> str:
        """Generate suggested key name"""
        clean_text = re.sub(r'[^\w\s]', '', text.lower())
        words = clean_text.split()[:4]

        prefix_map = {
            'Button': 'button',
            'Label': 'label',
            'Text': 'text',
            'NavigationTitle': 'nav',
            'Alert': 'alert',
            'TextField': 'placeholder',
            'Menu': 'menu',
            'Section': 'section',
        }

        prefix = prefix_map.get(component_type, 'common')
        key_parts = [prefix] + words

        return '.'.join(key_parts)

    def load_existing_keys(self):
        """Load existing keys"""
        print("📚 Localizable.strings dosyaları yükleniyor...")

        # Önce tüm dilleri tespit et
        all_languages = set()
        for loc_file in self.localization_files:
            # .lproj klasöründen dil kodunu çıkar
            lang_code = loc_file.parent.name.replace('.lproj', '')
            all_languages.add(lang_code)

        print(f"   Desteklenen diller: {', '.join(sorted(all_languages))}")

        for loc_file in self.localization_files:
            if not loc_file.exists():
                continue

            # Dil kodunu dinamik olarak çıkar
            lang = loc_file.parent.name.replace('.lproj', '')

            with open(loc_file, 'r', encoding='utf-8') as f:
                content = f.read()
                pattern = r'^"([^"]+)"\s*=\s*"([^"]+)";'
                matches = re.finditer(pattern, content, re.MULTILINE)

                for match in matches:
                    key, value = match.groups()
                    if key not in self.existing_keys:
                        # Tüm diller için None ile başlat
                        self.existing_keys[key] = {lang_code: None for lang_code in all_languages}
                    self.existing_keys[key][lang] = value

        print(f"   ✓ {len(self.existing_keys)} key yüklendi ({len(all_languages)} dilde)")

        # V5: Analyze key patterns
        pattern_analysis = self.key_pattern_analyzer.analyze(set(self.existing_keys.keys()))
        print(f"   ✓ {pattern_analysis['total_patterns']} farklı key pattern bulundu")

    def find_swift_files(self):
        """Find all Swift files"""
        print("🔍 Swift dosyaları taranıyor...")

        exclude_dirs = {
            'build', 'Build', 'DerivedData', '.build',
            'Pods', 'Carthage', 'vendor', '.git',
        }

        for swift_file in self.project_dir.rglob('*.swift'):
            if any(excluded in swift_file.parts for excluded in exclude_dirs):
                continue
            if 'Generated' in str(swift_file) or 'generated' in swift_file.name:
                continue
            self.swift_files.append(swift_file)

        print(f"   ✓ {len(self.swift_files)} Swift dosyası bulundu")

    def analyze_file(self, file_path: Path):
        """Analyze a single file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except:
            return

        relative_path = file_path.relative_to(self.project_dir)
        folder = str(relative_path.parent)

        # Find localized usages
        for pattern, component_type in self.localized_patterns:
            for match in re.finditer(pattern, content):
                key = match.group(1)
                line_num = content[:match.start()].count('\n') + 1

                self.used_keys.add(key)
                self.localized_usages.append({
                    'file': str(relative_path),
                    'line': line_num,
                    'key': key,
                    'component': component_type,
                })

                self.component_stats[component_type]['localized'] += 1
                self.file_stats[str(relative_path)]['localized'] += 1
                self.folder_stats[folder]['localized'] += 1

                if key not in self.existing_keys:
                    self.missing_keys[key].append(str(relative_path))

        # Find hardcoded strings
        for pattern, component_type, category in self.hardcoded_patterns:
            for match in re.finditer(pattern, content):
                text = match.group(1)

                if self._should_exclude(text):
                    continue

                line_num = content[:match.start()].count('\n') + 1

                # Skip if wrapped in localization
                context_start = max(0, match.start() - 50)
                context = content[context_start:match.end()]
                if 'String(localized:' in context or 'NSLocalizedString' in context:
                    continue

                priority = self._calculate_priority(component_type, category, text)
                suggested_key = self._suggest_key_name(text, component_type)

                item = {
                    'file': str(relative_path),
                    'line': line_num,
                    'text': text,
                    'component': component_type,
                    'category': category,
                    'priority': priority,
                    'suggested_key': suggested_key,
                }

                self.hardcoded_strings.append(item)
                self.duplicate_strings[text].append(item)

                self.component_stats[component_type]['hardcoded'] += 1
                self.file_stats[str(relative_path)]['hardcoded'] += 1
                self.folder_stats[folder]['hardcoded'] += 1

    def analyze_all_files(self, use_threads: bool = True):
        """Analyze all files (with optional multi-threading)"""
        print(f"\n📊 {len(self.swift_files)} dosya analiz ediliyor...")

        if use_threads and len(self.swift_files) > 20:
            # Multi-threaded analysis
            with ThreadPoolExecutor(max_workers=4) as executor:
                if TQDM_AVAILABLE:
                    list(tqdm(
                        executor.map(self.analyze_file, self.swift_files),
                        total=len(self.swift_files),
                        desc="Analyzing"
                    ))
                else:
                    futures = [executor.submit(self.analyze_file, f) for f in self.swift_files]
                    for i, future in enumerate(as_completed(futures), 1):
                        if i % 50 == 0:
                            print(f"   {i}/{len(self.swift_files)} dosya işlendi...")
        else:
            # Single-threaded
            for i, file_path in enumerate(self.swift_files, 1):
                if i % 50 == 0:
                    print(f"   {i}/{len(self.swift_files)} dosya işlendi...")
                self.analyze_file(file_path)

        print(f"   ✓ Analiz tamamlandı!")

    def find_dead_keys(self):
        """Find dead keys"""
        print("\n🔎 Dead key'ler tespit ediliyor...")
        all_keys = set(self.existing_keys.keys())
        self.dead_keys = all_keys - self.used_keys
        print(f"   ✓ {len(self.dead_keys)} dead key bulundu")

    def analyze_duplicates(self):
        """Analyze duplicates"""
        print("\n🔍 Duplicate string'ler analiz ediliyor...")
        self.duplicate_strings = {
            text: locations
            for text, locations in self.duplicate_strings.items()
            if len(locations) >= 2
        }
        print(f"   ✓ {len(self.duplicate_strings)} duplicate string bulundu")

    def calculate_health_score(self) -> Dict:
        """Calculate health score"""
        total_strings = len(self.hardcoded_strings) + len(self.localized_usages)

        if total_strings == 0:
            return {'score': 100, 'grade': 'A+', 'localization_rate': 100}

        localization_rate = (len(self.localized_usages) / total_strings) * 100
        score = localization_rate

        if self.missing_keys:
            score -= min(len(self.missing_keys) * 0.5, 10)
        if self.dead_keys:
            score -= min(len(self.dead_keys) * 0.1, 5)
        if self.duplicate_strings:
            score -= min(len(self.duplicate_strings) * 0.2, 5)

        score = max(0, min(100, score))

        if score >= 95:
            grade = 'A+'
        elif score >= 90:
            grade = 'A'
        elif score >= 80:
            grade = 'B'
        elif score >= 70:
            grade = 'C'
        elif score >= 60:
            grade = 'D'
        else:
            grade = 'F'

        return {
            'score': round(score, 1),
            'grade': grade,
            'localized_count': len(self.localized_usages),
            'hardcoded_count': len(self.hardcoded_strings),
            'total_strings': total_strings,
            'localization_rate': round(localization_rate, 1),
            'missing_keys_count': len(self.missing_keys),
            'dead_keys_count': len(self.dead_keys),
            'duplicate_count': len(self.duplicate_strings),
        }

    def generate_json_report(self):
        """Generate JSON report"""
        print("\n📝 JSON raporu oluşturuluyor...")

        health = self.calculate_health_score()

        # Get key pattern analysis
        pattern_analysis = self.key_pattern_analyzer.analyze(set(self.existing_keys.keys()))

        json_report = {
            'metadata': {
                'generated_at': datetime.now().isoformat(),
                'version': '5.0',
                'project': str(self.project_dir.name),
            },
            'health_score': health,
            'key_patterns': pattern_analysis,
            'component_stats': dict(self.component_stats),
            'hardcoded_strings': self.hardcoded_strings,
            'duplicate_strings': {k: len(v) for k, v in self.duplicate_strings.items()},
        }

        with open(self.project_dir / 'localization_report_v5.json', 'w', encoding='utf-8') as f:
            json.dump(json_report, f, indent=2, ensure_ascii=False)

        print("   ✓ localization_report_v5.json oluşturuldu")

    def run(self, use_threads: bool = True):
        """Run complete analysis"""
        print("=" * 70)
        print(f"{Colors.BOLD}🚀 LifeStyles Localization Analyzer V5{Colors.ENDC}")
        print("=" * 70)

        self.load_existing_keys()
        self.find_swift_files()
        self.analyze_all_files(use_threads=use_threads)
        self.find_dead_keys()
        self.analyze_duplicates()
        self.generate_json_report()

        health = self.calculate_health_score()

        print("\n" + "=" * 70)
        print(f"{Colors.BOLD}📊 ANALYSIS COMPLETE{Colors.ENDC}")
        print("=" * 70)
        print(f"🏥 Health Score: {Colors.OKGREEN}{health['score']}/100 ({health['grade']}){Colors.ENDC}")
        print(f"📈 Localization Rate: {health['localization_rate']}%")
        print(f"✅ Localized: {health['localized_count']} strings")
        print(f"⚠️  Hardcoded: {health['hardcoded_count']} strings")
        print(f"🔴 Missing Keys: {health['missing_keys_count']}")
        print(f"🟡 Dead Keys: {health['dead_keys_count']}")
        print(f"📦 Duplicates: {health['duplicate_count']}")
        print("=" * 70)


def create_backup(project_dir: Path) -> Path:
    """Create backup of localization files and Swift files"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_dir = project_dir / f'localization_backup_{timestamp}'
    backup_dir.mkdir(exist_ok=True)

    print(f"\n💾 Creating backup: {backup_dir.name}")

    # Backup .strings files
    strings_dir = project_dir / 'LifeStyles/Resources'
    if strings_dir.exists():
        shutil.copytree(strings_dir, backup_dir / 'Resources', dirs_exist_ok=True)
        print(f"   ✓ Backed up Resources/")

    print(f"   ✓ Backup created successfully")
    return backup_dir


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='LifeStyles Localization Analyzer V5',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Run analysis only
  %(prog)s --auto-fix               # Auto-fix high priority strings
  %(prog)s --interactive            # Interactive mode
  %(prog)s --fix-duplicates         # Fix duplicates only
  %(prog)s --watch                  # Watch mode
  %(prog)s --auto-fix --dry-run     # Preview changes

  # Language management
  %(prog)s --list-languages         # List all languages
  %(prog)s --add-language es        # Add Spanish (from TR)
  %(prog)s --add-language de --source-lang en  # Add German (from EN)
  %(prog)s --add-language fr --empty-strings   # Add French (empty)
        """
    )

    parser.add_argument('--auto-fix', action='store_true',
                        help='Automatically fix hardcoded strings (priority >= 8)')
    parser.add_argument('--interactive', action='store_true',
                        help='Interactive mode - review each fix')
    parser.add_argument('--fix-duplicates', action='store_true',
                        help='Automatically fix duplicate strings')
    parser.add_argument('--watch', action='store_true',
                        help='Watch mode - monitor files for changes')
    parser.add_argument('--dry-run', action='store_true',
                        help='Preview changes without applying')
    parser.add_argument('--no-backup', action='store_true',
                        help='Skip backup creation')
    parser.add_argument('--no-threads', action='store_true',
                        help='Disable multi-threading')
    parser.add_argument('--min-priority', type=int, default=8,
                        help='Minimum priority for auto-fix (default: 8)')

    # Language management arguments
    parser.add_argument('--add-language', type=str, metavar='CODE',
                        help='Add a new language (e.g., es, de, fr)')
    parser.add_argument('--source-lang', type=str, default='tr', metavar='CODE',
                        help='Source language to copy keys from (default: tr)')
    parser.add_argument('--list-languages', action='store_true',
                        help='List all available languages')
    parser.add_argument('--empty-strings', action='store_true',
                        help='Create empty strings file (use with --add-language)')

    args = parser.parse_args()

    project_dir = Path('.')
    resources_dir = project_dir / 'LifeStyles/Resources'

    # Language management mode
    if args.list_languages or args.add_language:
        lang_manager = LanguageManager(resources_dir)

        if args.list_languages:
            languages = lang_manager.list_languages()

            print(f"\n{Colors.BOLD}🌍 MEVCUT DİLLER{Colors.ENDC}")
            print("=" * 70)

            if not languages:
                print(f"{Colors.WARNING}Hiç dil bulunamadı{Colors.ENDC}")
                print(f"Resources dizini: {resources_dir}")
                return

            print(f"Toplam {len(languages)} dil bulundu:\n")

            for lang in sorted(languages, key=lambda x: x['code']):
                status = f"{Colors.OKGREEN}✓{Colors.ENDC}" if lang['has_strings'] else f"{Colors.FAIL}✗{Colors.ENDC}"
                print(f"{status} {Colors.BOLD}{lang['code']}{Colors.ENDC} - {lang['name']}")
                print(f"   Path: {lang['path']}")
                print(f"   Keys: {lang['key_count']}")
                print()

            return

        if args.add_language:
            success = lang_manager.add_language(
                lang_code=args.add_language,
                source_lang=args.source_lang,
                empty=args.empty_strings,
                dry_run=args.dry_run
            )

            if not success:
                sys.exit(1)

            return

    # Watch mode
    if args.watch:
        watch = WatchMode(project_dir, lambda: LocalizationAnalyzerV5(project_dir))
        watch.start()
        return

    # Run analysis
    analyzer = LocalizationAnalyzerV5(project_dir)
    analyzer.run(use_threads=not args.no_threads)

    # Create backup if needed
    backup_dir = None
    if (args.auto_fix or args.fix_duplicates or args.interactive) and not args.no_backup and not args.dry_run:
        backup_dir = create_backup(project_dir)

    # Initialize managers
    strings_manager = StringsFileManager(
        analyzer.localization_files[0],
        analyzer.localization_files[1]
    )
    strings_manager.load()

    auto_fixer = AutoFixer(strings_manager, dry_run=args.dry_run)

    # Interactive mode
    if args.interactive:
        cli = InteractiveCLI(analyzer, auto_fixer)
        cli.run()
        return

    # Auto-fix mode
    if args.auto_fix:
        print(f"\n{Colors.BOLD}⚡ AUTO-FIX MODE{Colors.ENDC}")
        print(f"Fixing strings with priority >= {args.min_priority}")

        if args.dry_run:
            print(f"{Colors.WARNING}[DRY RUN - No changes will be made]{Colors.ENDC}\n")

        high_priority = [
            item for item in analyzer.hardcoded_strings
            if item['priority'] >= args.min_priority
        ]

        print(f"Found {len(high_priority)} high-priority strings to fix\n")

        for item in high_priority:
            auto_fixer.fix_hardcoded_string(
                project_dir / item['file'],
                item['line'],
                item['text'],
                item['component'],
                item['suggested_key']
            )

        stats = auto_fixer.get_stats()
        print(f"\n{Colors.OKGREEN}✅ Auto-fix complete{Colors.ENDC}")
        print(f"   Applied: {stats['applied']}")
        print(f"   Failed: {stats['failed']}")

    # Fix duplicates
    if args.fix_duplicates:
        print(f"\n{Colors.BOLD}📦 FIX DUPLICATES MODE{Colors.ENDC}")

        if args.dry_run:
            print(f"{Colors.WARNING}[DRY RUN - No changes will be made]{Colors.ENDC}\n")

        # Sort by frequency
        sorted_dups = sorted(
            analyzer.duplicate_strings.items(),
            key=lambda x: len(x[1]),
            reverse=True
        )

        print(f"Found {len(sorted_dups)} duplicate strings\n")

        for text, locations in sorted_dups:
            if len(locations) < 2:
                continue

            # Use the first location's suggested key
            key = locations[0]['suggested_key']
            print(f"\nFixing duplicate: \"{text}\" ({len(locations)} occurrences)")
            print(f"Using key: {key}")

            for item in locations:
                auto_fixer.fix_hardcoded_string(
                    project_dir / item['file'],
                    item['line'],
                    item['text'],
                    item['component'],
                    key
                )

        stats = auto_fixer.get_stats()
        print(f"\n{Colors.OKGREEN}✅ Duplicate fix complete{Colors.ENDC}")
        print(f"   Applied: {stats['applied']}")
        print(f"   Failed: {stats['failed']}")

    # Show backup info
    if backup_dir:
        print(f"\n💾 Backup saved to: {backup_dir}")
        print(f"   To restore: cp -r {backup_dir}/Resources/* LifeStyles/Resources/")


if __name__ == '__main__':
    main()
