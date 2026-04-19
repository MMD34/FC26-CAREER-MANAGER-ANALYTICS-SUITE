import os
import glob

def replace_imports(directory, old_import, new_import):
    for filepath in glob.glob(os.path.join(directory, '**/*.py'), recursive=True):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        if old_import in content:
            content = content.replace(old_import, new_import)
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated {filepath}")

directory = r"c:\Users\mBell\Desktop\_PROJECTS_X\FC26-CAREER-MANAGER-ANALYTICS-SUITE\app"
replace_imports(directory, "from app.ui.widgets.chart_panel import ChartPanel", "from app.ui.charts.chart_panel import ChartPanel")
replace_imports(directory, "from app.ui.widgets.sparkline import Sparkline", "from app.ui.charts.sparkline import Sparkline")
