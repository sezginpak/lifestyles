#!/usr/bin/env python3
"""
Dead Key Remover - Kullanılmayan localization key'lerini temizler
V2.0 - Enhanced with backup, dry-run, and multi-language support
"""

import json
import re
import sys
import shutil
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Set
import argparse

class DeadKeyRemover:
    """Dead key removal with safety features"""

    def __init__(self, dry_run: bool = False, backup: bool = True):
        self.dry_run = dry_run
        self.backup = backup
        self.resources_path = Path('LifeStyles/Resources')
        self.report_files = [
            'localization_report_v5.json',
            'localization_report_v4.json',
            'localization_report.json'
        ]

    def find_report(self) -> Path:
        """Find most recent report file"""
        for report in self.report_files:
            if Path(report).exists():
                return Path(report)
        return None

    def load_dead_keys(self) -> List[str]:
        """Load dead keys from report"""
        report_path = self.find_report()

        if not report_path:
            print("❌ No localization report found!")
            print("💡 Run analyzer first:")
            print("   python3 analyze_localization_v5.py")
            sys.exit(1)

        print(f"📄 Using report: {report_path.name}\n")

        with open(report_path, 'r') as f:
            data = json.load(f)

        dead_keys = data.get('dead_keys', [])

        if not dead_keys:
            print("✅ No dead keys found!")
            sys.exit(0)

        return dead_keys

    def find_strings_files(self) -> List[Path]:
        """Find all .strings files"""
        if not self.resources_path.exists():
            print(f"❌ Resources path not found: {self.resources_path}")
            sys.exit(1)

        strings_files = list(self.resources_path.glob('*.lproj/Localizable.strings'))

        if not strings_files:
            print("❌ No .strings files found!")
            sys.exit(1)

        return strings_files

    def create_backup(self, file_path: Path):
        """Create backup of file"""
        if not self.backup or self.dry_run:
            return

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_dir = Path(f'localization_backup_{timestamp}')
        backup_dir.mkdir(exist_ok=True)

        backup_path = backup_dir / file_path.name
        shutil.copy2(file_path, backup_path)
        print(f"   💾 Backup: {backup_path}")

    def remove_dead_keys_from_file(self, file_path: Path, dead_keys: List[str]) -> int:
        """Remove dead keys from a single file"""
        print(f"\n🧹 Processing: {file_path.parent.name}/{file_path.name}")

        # Create backup
        self.create_backup(file_path)

        # Read file
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # Process lines
        new_lines = []
        removed_count = 0
        removed_keys = []

        for line in lines:
            is_dead = False

            # Check if line contains a dead key
            for key in dead_keys:
                # Match pattern: "key" = "value";
                if f'"{key}"' in line and '=' in line:
                    is_dead = True
                    removed_count += 1
                    removed_keys.append(key)
                    if not self.dry_run:
                        print(f"   ❌ {key}")
                    break

            if not is_dead:
                new_lines.append(line)

        # Write cleaned file (only if not dry-run)
        if not self.dry_run:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            print(f"   ✅ Removed {removed_count} keys")
        else:
            print(f"   🔍 Would remove {removed_count} keys:")
            for key in removed_keys[:5]:  # Show first 5
                print(f"      - {key}")
            if len(removed_keys) > 5:
                print(f"      ... and {len(removed_keys) - 5} more")

        return removed_count

    def run(self):
        """Main execution"""
        print("🗑️  Dead Key Remover V2.0")
        print("=" * 50)

        if self.dry_run:
            print("⚠️  DRY RUN MODE - No changes will be made\n")

        # Load dead keys
        dead_keys = self.load_dead_keys()

        print(f"📊 Found {len(dead_keys)} dead keys\n")

        # Show first 10 keys
        print("Dead keys (first 10):")
        for i, key in enumerate(sorted(dead_keys)[:10], 1):
            print(f"   {i}. {key}")
        if len(dead_keys) > 10:
            print(f"   ... and {len(dead_keys) - 10} more")

        # Find all .strings files
        strings_files = self.find_strings_files()

        print(f"\n📁 Found {len(strings_files)} localization files:")
        for f in strings_files:
            print(f"   - {f.parent.name}/{f.name}")

        # Remove dead keys from each file
        total_removed = 0

        for file_path in strings_files:
            removed = self.remove_dead_keys_from_file(file_path, dead_keys)
            total_removed += removed

        # Summary
        print("\n" + "=" * 50)
        if self.dry_run:
            print(f"🔍 DRY RUN: Would remove {total_removed} key occurrences")
            print("\n💡 Run without --dry-run to apply changes:")
            print("   python3 remove_dead_keys.py")
        else:
            print(f"🎉 Successfully removed {total_removed} key occurrences!")
            print(f"\n💡 Run analyzer again to verify:")
            print("   python3 analyze_localization_v5.py")

        if self.backup and not self.dry_run:
            print(f"\n💾 Backups created in localization_backup_* directories")


def main():
    """CLI entry point"""
    parser = argparse.ArgumentParser(
        description='Remove dead (unused) localization keys',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 remove_dead_keys.py --dry-run      # Preview changes
  python3 remove_dead_keys.py                # Remove dead keys
  python3 remove_dead_keys.py --no-backup    # Remove without backup
        """
    )

    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview changes without modifying files'
    )

    parser.add_argument(
        '--no-backup',
        action='store_true',
        help='Skip creating backup files'
    )

    args = parser.parse_args()

    # Run remover
    remover = DeadKeyRemover(
        dry_run=args.dry_run,
        backup=not args.no_backup
    )

    try:
        remover.run()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
