#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
标签打印工具 - Windows桌面应用
功能：输入数据后自动打印标签，支持自定义模板，数据校验
"""

import os
import sys
import json
import hashlib
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
from datetime import datetime
import tempfile
import subprocess

# 尝试导入打印相关库
try:
    import win32print
    import win32api
    HAS_WIN32 = True
except ImportError:
    HAS_WIN32 = False


class LabelTemplate:
    """标签模板类"""
    def __init__(self, name="", width=400, height=200, fields=None, content="", key_field=None):
        self.name = name
        self.width = width
        self.height = height
        self.fields = fields or []
        self.content = content
        self.key_field = key_field  # 用于校验的唯一字段

    def to_dict(self):
        return {
            "name": self.name,
            "width": self.width,
            "height": self.height,
            "fields": self.fields,
            "content": self.content,
            "key_field": self.key_field
        }

    @classmethod
    def from_dict(cls, data):
        return cls(
            name=data.get("name", ""),
            width=data.get("width", 400),
            height=data.get("height", 200),
            fields=data.get("fields", []),
            content=data.get("content", ""),
            key_field=data.get("key_field")
        )


class PrintRecord:
    """打印记录类"""
    def __init__(self, data_hash, data, template_name, timestamp):
        self.data_hash = data_hash
        self.data = data
        self.template_name = template_name
        self.timestamp = timestamp

    def to_dict(self):
        return {
            "data_hash": self.data_hash,
            "data": self.data,
            "template_name": self.template_name,
            "timestamp": self.timestamp
        }

    @classmethod
    def from_dict(cls, data):
        return cls(
            data_hash=data.get("data_hash", ""),
            data=data.get("data", {}),
            template_name=data.get("template_name", ""),
            timestamp=data.get("timestamp", "")
        )


class LabelPrintApp:
    """标签打印应用主类"""
    
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("标签打印工具 v1.1")
        self.root.geometry("950x750")
        self.root.minsize(850, 650)
        
        # 数据存储
        self.templates = []
        self.current_template = None
        self.print_records = []  # 打印记录
        self.config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "label_config.json")
        self.records_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "print_records.json")
        
        # 加载配置和记录
        self.load_config()
        self.load_records()
        
        # 创建UI
        self.create_ui()
        
        # 绑定关闭事件
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
    
    def create_ui(self):
        """创建用户界面"""
        # 主框架
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 顶部标题
        title_frame = ttk.Frame(main_frame)
        title_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(title_frame, text="标签打印工具", font=("微软雅黑", 16, "bold")).pack(side=tk.LEFT)
        ttk.Button(title_frame, text="模板管理", command=self.open_template_manager).pack(side=tk.RIGHT, padx=(5, 0))
        ttk.Button(title_frame, text="校验数据", command=self.open_verify_window).pack(side=tk.RIGHT)
        
        # 创建Notebook（选项卡）
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True)
        
        # 选项卡1：快速打印
        self.create_quick_print_tab()
        
        # 选项卡2：批量打印
        self.create_batch_print_tab()
        
        # 选项卡3：打印历史
        self.create_history_tab()
        
        # 选项卡4：已打印数据
        self.create_printed_data_tab()
        
        # 状态栏
        self.status_var = tk.StringVar(value="就绪")
        status_bar = ttk.Label(main_frame, textvariable=self.status_var, relief=tk.SUNKEN)
        status_bar.pack(fill=tk.X, pady=(10, 0))
    
    def create_quick_print_tab(self):
        """创建快速打印选项卡"""
        tab = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(tab, text="快速打印")
        
        # 模板选择
        template_frame = ttk.LabelFrame(tab, text="选择模板", padding="10")
        template_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.template_var = tk.StringVar()
        self.template_combo = ttk.Combobox(template_frame, textvariable=self.template_var, state="readonly")
        self.template_combo.pack(fill=tk.X)
        self.template_combo.bind("<<ComboboxSelected>>", self.on_template_selected)
        
        # 动态字段区域
        self.fields_frame = ttk.LabelFrame(tab, text="输入数据", padding="10")
        self.fields_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.field_entries = {}
        
        # 快速输入区域
        quick_frame = ttk.LabelFrame(tab, text="快速输入", padding="10")
        quick_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(quick_frame, text="输入数据（每行一个，自动填充到对应字段）：").pack(anchor=tk.W)
        self.quick_input = tk.Text(quick_frame, height=5)
        self.quick_input.pack(fill=tk.X, pady=(5, 0))
        
        ttk.Button(quick_frame, text="自动填充", command=self.auto_fill_fields).pack(pady=(5, 0))
        
        # 校验选项
        verify_frame = ttk.Frame(tab)
        verify_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.verify_before_print = tk.BooleanVar(value=True)
        ttk.Checkbutton(verify_frame, text="打印前校验数据是否已打印", 
                       variable=self.verify_before_print).pack(side=tk.LEFT)
        
        # 按钮区域
        btn_frame = ttk.Frame(tab)
        btn_frame.pack(fill=tk.X, pady=(10, 0))
        
        ttk.Button(btn_frame, text="预览标签", command=self.preview_label).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(btn_frame, text="打印标签", command=self.print_label).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(btn_frame, text="清空输入", command=self.clear_fields).pack(side=tk.LEFT)
        
        # 预览区域
        preview_frame = ttk.LabelFrame(tab, text="预览", padding="10")
        preview_frame.pack(fill=tk.BOTH, expand=True, pady=(10, 0))
        
        self.preview_text = tk.Text(preview_frame, state=tk.DISABLED, wrap=tk.WORD)
        self.preview_text.pack(fill=tk.BOTH, expand=True)
        
        # 刷新模板列表
        self.refresh_template_list()
    
    def create_batch_print_tab(self):
        """创建批量打印选项卡"""
        tab = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(tab, text="批量打印")
        
        # 模板选择
        template_frame = ttk.LabelFrame(tab, text="选择模板", padding="10")
        template_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.batch_template_var = tk.StringVar()
        self.batch_template_combo = ttk.Combobox(template_frame, textvariable=self.batch_template_var, state="readonly")
        self.batch_template_combo.pack(fill=tk.X)
        
        # 数据输入
        data_frame = ttk.LabelFrame(tab, text="批量数据", padding="10")
        data_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        ttk.Label(data_frame, text="输入数据（JSON格式或CSV格式）：").pack(anchor=tk.W)
        self.batch_input = tk.Text(data_frame, wrap=tk.WORD)
        self.batch_input.pack(fill=tk.BOTH, expand=True, pady=(5, 0))
        
        # 格式说明
        format_frame = ttk.Frame(data_frame)
        format_frame.pack(fill=tk.X, pady=(5, 0))
        ttk.Label(format_frame, text="格式示例：", font=("微软雅黑", 9, "bold")).pack(anchor=tk.W)
        ttk.Label(format_frame, text='JSON: [{"姓名":"张三","电话":"123"},{"姓名":"李四","电话":"456"}]',
                 font=("Consolas", 9)).pack(anchor=tk.W)
        ttk.Label(format_frame, text='CSV: 姓名,电话\\n张三,123\\n李四,456',
                 font=("Consolas", 9)).pack(anchor=tk.W)
        
        # 校验选项
        verify_frame = ttk.Frame(tab)
        verify_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.batch_verify = tk.BooleanVar(value=True)
        ttk.Checkbutton(verify_frame, text="打印前校验数据是否已打印",
                       variable=self.batch_verify).pack(side=tk.LEFT)
        
        self.skip_duplicates = tk.BooleanVar(value=True)
        ttk.Checkbutton(verify_frame, text="自动跳过已打印数据",
                       variable=self.skip_duplicates).pack(side=tk.LEFT, padx=(20, 0))
        
        # 按钮区域
        btn_frame = ttk.Frame(tab)
        btn_frame.pack(fill=tk.X, pady=(10, 0))
        
        ttk.Button(btn_frame, text="解析数据", command=self.parse_batch_data).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(btn_frame, text="校验数据", command=self.verify_batch_data).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(btn_frame, text="批量打印", command=self.batch_print).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(btn_frame, text="导入文件", command=self.import_batch_file).pack(side=tk.LEFT)
        
        # 数据预览
        preview_frame = ttk.LabelFrame(tab, text="数据预览", padding="10")
        preview_frame.pack(fill=tk.BOTH, expand=True, pady=(10, 0))
        
        # 创建Treeview显示表格数据
        self.batch_tree = ttk.Treeview(preview_frame, show="headings")
        self.batch_tree.pack(fill=tk.BOTH, expand=True, side=tk.LEFT)
        
        # 滚动条
        scrollbar = ttk.Scrollbar(preview_frame, orient=tk.VERTICAL, command=self.batch_tree.yview)
        self.batch_tree.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        self.batch_data = []
    
    def create_history_tab(self):
        """创建打印历史选项卡"""
        tab = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(tab, text="打印历史")
        
        # 历史记录列表
        history_frame = ttk.LabelFrame(tab, text="打印记录", padding="10")
        history_frame.pack(fill=tk.BOTH, expand=True)
        
        self.history_tree = ttk.Treeview(history_frame, columns=("time", "template", "count", "status"), show="headings")
        self.history_tree.heading("time", text="时间")
        self.history_tree.heading("template", text="模板")
        self.history_tree.heading("count", text="数量")
        self.history_tree.heading("status", text="状态")
        self.history_tree.pack(fill=tk.BOTH, expand=True)
        
        # 按钮区域
        btn_frame = ttk.Frame(tab)
        btn_frame.pack(fill=tk.X, pady=(10, 0))
        
        ttk.Button(btn_frame, text="清空历史", command=self.clear_history).pack(side=tk.LEFT)
        ttk.Button(btn_frame, text="导出历史", command=self.export_history).pack(side=tk.LEFT, padx=(10, 0))
    
    def create_printed_data_tab(self):
        """创建已打印数据选项卡"""
        tab = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(tab, text="已打印数据")
        
        # 说明
        ttk.Label(tab, text="已打印的数据记录，用于防止重复打印", font=("微软雅黑", 10)).pack(anchor=tk.W, pady=(0, 10))
        
        # 搜索框
        search_frame = ttk.Frame(tab)
        search_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(search_frame, text="搜索：").pack(side=tk.LEFT)
        self.search_var = tk.StringVar()
        self.search_entry = ttk.Entry(search_frame, textvariable=self.search_var)
        self.search_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(5, 10))
        ttk.Button(search_frame, text="搜索", command=self.search_records).pack(side=tk.LEFT)
        ttk.Button(search_frame, text="显示全部", command=self.refresh_printed_data).pack(side=tk.LEFT, padx=(5, 0))
        
        # 数据列表
        data_frame = ttk.LabelFrame(tab, text="已打印数据", padding="10")
        data_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.printed_tree = ttk.Treeview(data_frame, columns=("hash", "template", "time", "data"), show="headings")
        self.printed_tree.heading("hash", text="数据哈希")
        self.printed_tree.heading("template", text="模板")
        self.printed_tree.heading("time", text="打印时间")
        self.printed_tree.heading("data", text="数据内容")
        self.printed_tree.column("hash", width=100)
        self.printed_tree.column("template", width=100)
        self.printed_tree.column("time", width=150)
        self.printed_tree.column("data", width=300)
        self.printed_tree.pack(fill=tk.BOTH, expand=True, side=tk.LEFT)
        
        # 滚动条
        scrollbar = ttk.Scrollbar(data_frame, orient=tk.VERTICAL, command=self.printed_tree.yview)
        self.printed_tree.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # 按钮区域
        btn_frame = ttk.Frame(tab)
        btn_frame.pack(fill=tk.X)
        
        ttk.Button(btn_frame, text="刷新", command=self.refresh_printed_data).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(btn_frame, text="清空记录", command=self.clear_printed_data).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(btn_frame, text="导出记录", command=self.export_printed_data).pack(side=tk.LEFT)
        
        # 刷新数据
        self.refresh_printed_data()
    
    def get_data_hash(self, data, template_name):
        """生成数据的唯一哈希值"""
        # 将数据转换为字符串
        data_str = json.dumps(data, sort_keys=True) + template_name
        return hashlib.md5(data_str.encode('utf-8')).hexdigest()[:16]
    
    def is_data_printed(self, data, template_name):
        """检查数据是否已打印"""
        data_hash = self.get_data_hash(data, template_name)
        return any(r.data_hash == data_hash for r in self.print_records)
    
    def add_print_record(self, data, template_name):
        """添加打印记录"""
        data_hash = self.get_data_hash(data, template_name)
        record = PrintRecord(
            data_hash=data_hash,
            data=data,
            template_name=template_name,
            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        )
        self.print_records.append(record)
        self.save_records()
    
    def load_records(self):
        """加载打印记录"""
        try:
            if os.path.exists(self.records_file):
                with open(self.records_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.print_records = [PrintRecord.from_dict(r) for r in data.get('records', [])]
        except Exception as e:
            print(f"加载记录失败: {e}")
            self.print_records = []
    
    def save_records(self):
        """保存打印记录"""
        try:
            data = {
                'records': [r.to_dict() for r in self.print_records]
            }
            with open(self.records_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"保存记录失败: {e}")
    
    def refresh_printed_data(self):
        """刷新已打印数据"""
        for item in self.printed_tree.get_children():
            self.printed_tree.delete(item)
        
        for record in reversed(self.print_records):
            data_str = json.dumps(record.data, ensure_ascii=False)[:50]
            self.printed_tree.insert('', 0, values=(
                record.data_hash,
                record.template_name,
                record.timestamp,
                data_str
            ))
    
    def search_records(self):
        """搜索记录"""
        keyword = self.search_var.get().strip().lower()
        if not keyword:
            self.refresh_printed_data()
            return
        
        for item in self.printed_tree.get_children():
            self.printed_tree.delete(item)
        
        for record in reversed(self.print_records):
            data_str = json.dumps(record.data, ensure_ascii=False).lower()
            if keyword in data_str or keyword in record.template_name.lower():
                self.printed_tree.insert('', 0, values=(
                    record.data_hash,
                    record.template_name,
                    record.timestamp,
                    data_str[:50]
                ))
    
    def clear_printed_data(self):
        """清空已打印数据"""
        if messagebox.askyesno("确认", "确定要清空所有已打印数据记录吗？这将允许重新打印所有数据。"):
            self.print_records.clear()
            self.save_records()
            self.refresh_printed_data()
            messagebox.showinfo("成功", "已打印数据记录已清空")
    
    def export_printed_data(self):
        """导出已打印数据"""
        file_path = filedialog.asksaveasfilename(
            title="导出已打印数据",
            defaultextension=".json",
            filetypes=[("JSON文件", "*.json")]
        )
        
        if file_path:
            try:
                data = {
                    'export_time': datetime.now().isoformat(),
                    'total_records': len(self.print_records),
                    'records': [r.to_dict() for r in self.print_records]
                }
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                messagebox.showinfo("成功", f"已导出 {len(self.print_records)} 条记录")
            except Exception as e:
                messagebox.showerror("错误", f"导出失败: {e}")
    
    def open_verify_window(self):
        """打开数据校验窗口"""
        VerifyWindow(self.root, self.templates, self.print_records)
    
    def refresh_template_list(self):
        """刷新模板列表"""
        template_names = [t.name for t in self.templates]
        self.template_combo['values'] = template_names
        self.batch_template_combo['values'] = template_names
        
        if template_names:
            self.template_combo.current(0)
            self.batch_template_combo.current(0)
            self.on_template_selected(None)
    
    def on_template_selected(self, event):
        """模板选择事件"""
        template_name = self.template_var.get()
        self.current_template = next((t for t in self.templates if t.name == template_name), None)
        
        if self.current_template:
            self.create_field_inputs()
            self.update_preview()
    
    def create_field_inputs(self):
        """根据模板创建输入字段"""
        for widget in self.fields_frame.winfo_children():
            widget.destroy()
        self.field_entries.clear()
        
        if not self.current_template or not self.current_template.fields:
            return
        
        for i, field in enumerate(self.current_template.fields):
            frame = ttk.Frame(self.fields_frame)
            frame.pack(fill=tk.X, pady=(0, 5))
            
            ttk.Label(frame, text=f"{field['name']}：", width=15).pack(side=tk.LEFT)
            
            entry = ttk.Entry(frame)
            entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
            entry.insert(0, field.get('default', ''))
            
            self.field_entries[field['name']] = entry
    
    def auto_fill_fields(self):
        """自动填充字段"""
        quick_text = self.quick_input.get("1.0", tk.END).strip()
        if not quick_text:
            return
        
        lines = quick_text.split('\n')
        field_names = list(self.field_entries.keys())
        
        for i, line in enumerate(lines):
            if i < len(field_names) and line.strip():
                self.field_entries[field_names[i]].delete(0, tk.END)
                self.field_entries[field_names[i]].insert(0, line.strip())
    
    def update_preview(self):
        """更新预览"""
        if not self.current_template:
            return
        
        data = {}
        for name, entry in self.field_entries.items():
            data[name] = entry.get()
        
        preview = f"模板: {self.current_template.name}\n"
        preview += f"尺寸: {self.current_template.width} x {self.current_template.height}\n"
        preview += "-" * 40 + "\n"
        
        for name, value in data.items():
            preview += f"{name}: {value}\n"
        
        self.preview_text.config(state=tk.NORMAL)
        self.preview_text.delete("1.0", tk.END)
        self.preview_text.insert("1.0", preview)
        self.preview_text.config(state=tk.DISABLED)
    
    def preview_label(self):
        """预览标签"""
        if not self.current_template:
            messagebox.showwarning("警告", "请先选择模板")
            return
        
        self.update_preview()
        messagebox.showinfo("预览", "标签预览已更新，请查看预览区域")
    
    def print_label(self):
        """打印标签"""
        if not self.current_template:
            messagebox.showwarning("警告", "请先选择模板")
            return
        
        # 收集字段数据
        data = {}
        for name, entry in self.field_entries.items():
            data[name] = entry.get()
        
        # 校验数据
        if self.verify_before_print.get():
            if self.is_data_printed(data, self.current_template.name):
                result = messagebox.askyesnocancel(
                    "数据已打印",
                    "该数据已经打印过！\n\n"
                    f"数据: {json.dumps(data, ensure_ascii=False)}\n\n"
                    "点击「是」继续打印\n"
                    "点击「否」跳过\n"
                    "点击「取消」取消操作"
                )
                if result is None:  # 取消
                    return
                elif not result:  # 否
                    messagebox.showinfo("跳过", "已跳过该数据")
                    return
        
        # 生成标签内容
        content = self.generate_label_content(data)
        
        # 保存到临时文件
        temp_file = os.path.join(tempfile.gettempdir(), "label_print.txt")
        with open(temp_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        # 尝试打印
        if self.try_print(temp_file):
            self.add_print_record(data, self.current_template.name)
            self.add_history(self.current_template.name, 1, "成功")
            messagebox.showinfo("成功", "标签已发送到打印机")
        else:
            self.open_file(temp_file)
            self.add_history(self.current_template.name, 1, "已打开文件")
    
    def generate_label_content(self, data):
        """生成标签内容"""
        if self.current_template.content:
            content = self.current_template.content
            for name, value in data.items():
                content = content.replace(f"{{{name}}}", value)
            return content
        else:
            lines = []
            for name, value in data.items():
                lines.append(f"{name}: {value}")
            return '\n'.join(lines)
    
    def try_print(self, file_path):
        """尝试打印文件"""
        try:
            if sys.platform == 'win32':
                if HAS_WIN32:
                    win32api.ShellExecute(0, "print", file_path, None, ".", 0)
                    return True
                else:
                    os.startfile(file_path, "print")
                    return True
            elif sys.platform == 'darwin':
                subprocess.run(["lpr", file_path], check=True)
                return True
            else:
                subprocess.run(["lp", file_path], check=True)
                return True
        except Exception as e:
            print(f"打印失败: {e}")
            return False
    
    def open_file(self, file_path):
        """打开文件"""
        try:
            if sys.platform == 'win32':
                os.startfile(file_path)
            elif sys.platform == 'darwin':
                subprocess.run(["open", file_path])
            else:
                subprocess.run(["xdg-open", file_path])
        except Exception as e:
            messagebox.showerror("错误", f"无法打开文件: {e}")
    
    def clear_fields(self):
        """清空输入字段"""
        for entry in self.field_entries.values():
            entry.delete(0, tk.END)
        self.quick_input.delete("1.0", tk.END)
        self.update_preview()
    
    def parse_batch_data(self):
        """解析批量数据"""
        raw_text = self.batch_input.get("1.0", tk.END).strip()
        if not raw_text:
            messagebox.showwarning("警告", "请输入数据")
            return
        
        try:
            if raw_text.startswith('['):
                self.batch_data = json.loads(raw_text)
            else:
                lines = raw_text.split('\n')
                if len(lines) < 2:
                    messagebox.showerror("错误", "数据格式不正确")
                    return
                
                headers = [h.strip() for h in lines[0].split(',')]
                self.batch_data = []
                
                for line in lines[1:]:
                    if line.strip():
                        values = [v.strip() for v in line.split(',')]
                        row = dict(zip(headers, values))
                        self.batch_data.append(row)
            
            self.update_batch_preview()
            messagebox.showinfo("成功", f"解析成功，共 {len(self.batch_data)} 条数据")
            
        except Exception as e:
            messagebox.showerror("错误", f"数据解析失败: {e}")
    
    def verify_batch_data(self):
        """校验批量数据"""
        if not self.batch_data:
            messagebox.showwarning("警告", "请先解析数据")
            return
        
        template_name = self.batch_template_var.get()
        if not template_name:
            messagebox.showwarning("警告", "请选择模板")
            return
        
        # 统计已打印和未打印
        printed_count = 0
        unprinted_count = 0
        printed_items = []
        
        for data in self.batch_data:
            if self.is_data_printed(data, template_name):
                printed_count += 1
                printed_items.append(data)
            else:
                unprinted_count += 1
        
        # 显示结果
        result_msg = f"数据校验完成：\n\n"
        result_msg += f"总数据量: {len(self.batch_data)}\n"
        result_msg += f"未打印: {unprinted_count}\n"
        result_msg += f"已打印: {printed_count}\n"
        
        if printed_items:
            result_msg += f"\n已打印数据示例:\n"
            for item in printed_items[:3]:
                result_msg += f"  - {json.dumps(item, ensure_ascii=False)}\n"
        
        messagebox.showinfo("校验结果", result_msg)
    
    def update_batch_preview(self):
        """更新批量数据预览"""
        for item in self.batch_tree.get_children():
            self.batch_tree.delete(item)
        
        if not self.batch_data:
            return
        
        columns = list(self.batch_data[0].keys())
        self.batch_tree['columns'] = columns
        
        for col in columns:
            self.batch_tree.heading(col, text=col)
            self.batch_tree.column(col, width=100)
        
        for row in self.batch_data:
            values = [row.get(col, '') for col in columns]
            self.batch_tree.insert('', tk.END, values=values)
    
    def batch_print(self):
        """批量打印"""
        if not self.batch_data:
            messagebox.showwarning("警告", "请先解析数据")
            return
        
        template_name = self.batch_template_var.get()
        template = next((t for t in self.templates if t.name == template_name), None)
        
        if not template:
            messagebox.showwarning("警告", "请选择模板")
            return
        
        # 检查重复数据
        if self.batch_verify.get():
            printed_items = []
            for data in self.batch_data:
                if self.is_data_printed(data, template_name):
                    printed_items.append(data)
            
            if printed_items:
                if self.skip_duplicates.get():
                    # 自动跳过已打印数据
                    self.batch_data = [d for d in self.batch_data if not self.is_data_printed(d, template_name)]
                    messagebox.showinfo("跳过", f"已跳过 {len(printed_items)} 条已打印数据，剩余 {len(self.batch_data)} 条")
                else:
                    result = messagebox.askyesnocancel(
                        "发现重复数据",
                        f"发现 {len(printed_items)} 条数据已打印过！\n\n"
                        "点击「是」继续打印全部\n"
                        "点击「否」跳过已打印数据\n"
                        "点击「取消」取消操作"
                    )
                    if result is None:
                        return
                    elif not result:
                        self.batch_data = [d for d in self.batch_data if not self.is_data_printed(d, template_name)]
        
        if not self.batch_data:
            messagebox.showinfo("完成", "没有需要打印的数据")
            return
        
        # 确认打印
        if not messagebox.askyesno("确认", f"确定要打印 {len(self.batch_data)} 个标签吗？"):
            return
        
        success_count = 0
        for data in self.batch_data:
            content = self.generate_label_content(data)
            
            temp_file = os.path.join(tempfile.gettempdir(), f"label_{success_count + 1}.txt")
            with open(temp_file, 'w', encoding='utf-8') as f:
                f.write(content)
            
            if self.try_print(temp_file):
                self.add_print_record(data, template_name)
                success_count += 1
        
        self.add_history(template_name, success_count, "成功")
        self.update_batch_preview()  # 更新预览显示
        messagebox.showinfo("完成", f"批量打印完成，成功 {success_count}/{len(self.batch_data) + success_count} 个")
    
    def import_batch_file(self):
        """导入批量数据文件"""
        file_path = filedialog.askopenfilename(
            title="选择数据文件",
            filetypes=[("JSON文件", "*.json"), ("CSV文件", "*.csv"), ("文本文件", "*.txt")]
        )
        
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                self.batch_input.delete("1.0", tk.END)
                self.batch_input.insert("1.0", content)
                self.parse_batch_data()
                
            except Exception as e:
                messagebox.showerror("错误", f"文件读取失败: {e}")
    
    def add_history(self, template_name, count, status):
        """添加打印历史"""
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.history_tree.insert('', 0, values=(now, template_name, count, status))
    
    def clear_history(self):
        """清空打印历史"""
        for item in self.history_tree.get_children():
            self.history_tree.delete(item)
    
    def export_history(self):
        """导出打印历史"""
        file_path = filedialog.asksaveasfilename(
            title="导出历史",
            defaultextension=".csv",
            filetypes=[("CSV文件", "*.csv")]
        )
        
        if file_path:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write("时间,模板,数量,状态\n")
                    for item in self.history_tree.get_children():
                        values = self.history_tree.item(item)['values']
                        f.write(f"{values[0]},{values[1]},{values[2]},{values[3]}\n")
                
                messagebox.showinfo("成功", "历史记录已导出")
            except Exception as e:
                messagebox.showerror("错误", f"导出失败: {e}")
    
    def open_template_manager(self):
        """打开模板管理器"""
        TemplateManagerWindow(self.root, self.templates, self.on_templates_updated)
    
    def on_templates_updated(self, templates):
        """模板更新回调"""
        self.templates = templates
        self.save_config()
        self.refresh_template_list()
    
    def load_config(self):
        """加载配置"""
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.templates = [LabelTemplate.from_dict(t) for t in data.get('templates', [])]
        except Exception as e:
            print(f"加载配置失败: {e}")
            self.templates = self.get_default_templates()
    
    def save_config(self):
        """保存配置"""
        try:
            data = {
                'templates': [t.to_dict() for t in self.templates]
            }
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"保存配置失败: {e}")
    
    def get_default_templates(self):
        """获取默认模板"""
        return [
            LabelTemplate(
                name="商品标签",
                width=400,
                height=200,
                fields=[
                    {"name": "商品名称", "default": ""},
                    {"name": "价格", "default": ""},
                    {"name": "条形码", "default": ""},
                    {"name": "生产日期", "default": ""},
                ],
                content="商品: {商品名称}\n价格: ¥{价格}\n条码: {条形码}\n日期: {生产日期}",
                key_field="条形码"
            ),
            LabelTemplate(
                name="快递标签",
                width=400,
                height=300,
                fields=[
                    {"name": "收件人", "default": ""},
                    {"name": "电话", "default": ""},
                    {"name": "地址", "default": ""},
                    {"name": "单号", "default": ""},
                ],
                content="收件人: {收件人}\n电话: {电话}\n地址: {地址}\n单号: {单号}",
                key_field="单号"
            ),
            LabelTemplate(
                name="资产标签",
                width=300,
                height=150,
                fields=[
                    {"name": "资产编号", "default": ""},
                    {"name": "设备名称", "default": ""},
                    {"name": "使用部门", "default": ""},
                    {"name": "购买日期", "default": ""},
                ],
                content="编号: {资产编号}\n设备: {设备名称}\n部门: {使用部门}\n日期: {购买日期}",
                key_field="资产编号"
            ),
        ]
    
    def on_closing(self):
        """关闭应用"""
        self.save_config()
        self.save_records()
        self.root.destroy()
    
    def run(self):
        """运行应用"""
        self.root.mainloop()


class VerifyWindow:
    """数据校验窗口"""
    
    def __init__(self, parent, templates, print_records):
        self.parent = parent
        self.templates = templates
        self.print_records = print_records
        
        # 创建窗口
        self.window = tk.Toplevel(parent)
        self.window.title("数据校验")
        self.window.geometry("500x400")
        self.window.transient(parent)
        self.window.grab_set()
        
        # 创建UI
        self.create_ui()
    
    def create_ui(self):
        """创建用户界面"""
        main_frame = ttk.Frame(self.window, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 模板选择
        template_frame = ttk.LabelFrame(main_frame, text="选择模板", padding="10")
        template_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.template_var = tk.StringVar()
        self.template_combo = ttk.Combobox(template_frame, textvariable=self.template_var, state="readonly")
        self.template_combo['values'] = [t.name for t in self.templates]
        self.template_combo.pack(fill=tk.X)
        
        # 数据输入
        input_frame = ttk.LabelFrame(main_frame, text="输入数据（每行一个，或JSON数组）", padding="10")
        input_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.data_input = tk.Text(input_frame, wrap=tk.WORD)
        self.data_input.pack(fill=tk.BOTH, expand=True)
        
        # 按钮区域
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(fill=tk.X)
        
        ttk.Button(btn_frame, text="校验", command=self.verify).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(btn_frame, text="关闭", command=self.window.destroy).pack(side=tk.RIGHT)
        
        # 结果区域
        result_frame = ttk.LabelFrame(main_frame, text="校验结果", padding="10")
        result_frame.pack(fill=tk.X, pady=(10, 0))
        
        self.result_text = tk.Text(result_frame, height=5, state=tk.DISABLED)
        self.result_text.pack(fill=tk.X)
    
    def verify(self):
        """校验数据"""
        template_name = self.template_var.get()
        if not template_name:
            messagebox.showwarning("警告", "请选择模板")
            return
        
        raw_text = self.data_input.get("1.0", tk.END).strip()
        if not raw_text:
            messagebox.showwarning("警告", "请输入数据")
            return
        
        try:
            # 解析数据
            if raw_text.startswith('['):
                data_list = json.loads(raw_text)
            else:
                lines = raw_text.split('\n')
                data_list = [{"值": line.strip()} for line in lines if line.strip()]
            
            # 校验数据
            printed_count = 0
            unprinted_count = 0
            printed_items = []
            
            for data in data_list:
                data_hash = hashlib.md5((json.dumps(data, sort_keys=True) + template_name).encode('utf-8')).hexdigest()[:16]
                if any(r.data_hash == data_hash for r in self.print_records):
                    printed_count += 1
                    printed_items.append(data)
                else:
                    unprinted_count += 1
            
            # 显示结果
            result = f"校验完成：\n"
            result += f"总数据量: {len(data_list)}\n"
            result += f"未打印: {unprinted_count}\n"
            result += f"已打印: {printed_count}\n"
            
            if printed_items:
                result += f"\n已打印数据:\n"
                for item in printed_items:
                    result += f"  - {json.dumps(item, ensure_ascii=False)}\n"
            
            self.result_text.config(state=tk.NORMAL)
            self.result_text.delete("1.0", tk.END)
            self.result_text.insert("1.0", result)
            self.result_text.config(state=tk.DISABLED)
            
        except Exception as e:
            messagebox.showerror("错误", f"数据解析失败: {e}")


class TemplateManagerWindow:
    """模板管理窗口"""
    
    def __init__(self, parent, templates, callback):
        self.parent = parent
        self.templates = templates.copy()
        self.callback = callback
        
        # 创建窗口
        self.window = tk.Toplevel(parent)
        self.window.title("模板管理")
        self.window.geometry("600x500")
        self.window.transient(parent)
        self.window.grab_set()
        
        # 创建UI
        self.create_ui()
        
        # 刷新列表
        self.refresh_list()
    
    def create_ui(self):
        """创建用户界面"""
        main_frame = ttk.Frame(self.window, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 模板列表
        list_frame = ttk.LabelFrame(main_frame, text="模板列表", padding="10")
        list_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.template_list = ttk.Treeview(list_frame, columns=("name", "fields", "key"), show="headings")
        self.template_list.heading("name", text="模板名称")
        self.template_list.heading("fields", text="字段数")
        self.template_list.heading("key", text="校验字段")
        self.template_list.pack(fill=tk.BOTH, expand=True)
        
        # 按钮区域
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(fill=tk.X)
        
        ttk.Button(btn_frame, text="新建模板", command=self.create_template).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btn_frame, text="编辑模板", command=self.edit_template).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btn_frame, text="删除模板", command=self.delete_template).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btn_frame, text="导入模板", command=self.import_template).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btn_frame, text="导出模板", command=self.export_template).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(btn_frame, text="保存", command=self.save).pack(side=tk.RIGHT)
    
    def refresh_list(self):
        """刷新模板列表"""
        for item in self.template_list.get_children():
            self.template_list.delete(item)
        
        for template in self.templates:
            self.template_list.insert('', tk.END, values=(
                template.name,
                len(template.fields),
                template.key_field or "无"
            ))
    
    def create_template(self):
        """创建新模板"""
        TemplateEditWindow(self.window, None, self.on_template_saved)
    
    def edit_template(self):
        """编辑模板"""
        selection = self.template_list.selection()
        if not selection:
            messagebox.showwarning("警告", "请选择要编辑的模板")
            return
        
        item = self.template_list.item(selection[0])
        template_name = item['values'][0]
        template = next((t for t in self.templates if t.name == template_name), None)
        
        if template:
            TemplateEditWindow(self.window, template, self.on_template_saved)
    
    def delete_template(self):
        """删除模板"""
        selection = self.template_list.selection()
        if not selection:
            messagebox.showwarning("警告", "请选择要删除的模板")
            return
        
        item = self.template_list.item(selection[0])
        template_name = item['values'][0]
        
        if messagebox.askyesno("确认", f"确定要删除模板 '{template_name}' 吗？"):
            self.templates = [t for t in self.templates if t.name != template_name]
            self.refresh_list()
    
    def import_template(self):
        """导入模板"""
        file_path = filedialog.askopenfilename(
            title="导入模板",
            filetypes=[("JSON文件", "*.json")]
        )
        
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                if isinstance(data, list):
                    for item in data:
                        self.templates.append(LabelTemplate.from_dict(item))
                else:
                    self.templates.append(LabelTemplate.from_dict(data))
                
                self.refresh_list()
                messagebox.showinfo("成功", "模板导入成功")
            except Exception as e:
                messagebox.showerror("错误", f"导入失败: {e}")
    
    def export_template(self):
        """导出模板"""
        file_path = filedialog.asksaveasfilename(
            title="导出模板",
            defaultextension=".json",
            filetypes=[("JSON文件", "*.json")]
        )
        
        if file_path:
            try:
                data = [t.to_dict() for t in self.templates]
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                
                messagebox.showinfo("成功", "模板导出成功")
            except Exception as e:
                messagebox.showerror("错误", f"导出失败: {e}")
    
    def on_template_saved(self, template):
        """模板保存回调"""
        existing = next((i for i, t in enumerate(self.templates) if t.name == template.name), None)
        if existing is not None:
            self.templates[existing] = template
        else:
            self.templates.append(template)
        
        self.refresh_list()
    
    def save(self):
        """保存并关闭"""
        self.callback(self.templates)
        self.window.destroy()


class TemplateEditWindow:
    """模板编辑窗口"""
    
    def __init__(self, parent, template, callback):
        self.parent = parent
        self.template = template
        self.callback = callback
        self.fields = template.fields.copy() if template else []
        
        # 创建窗口
        self.window = tk.Toplevel(parent)
        self.window.title("编辑模板" if template else "新建模板")
        self.window.geometry("500x650")
        self.window.transient(parent)
        self.window.grab_set()
        
        # 创建UI
        self.create_ui()
        
        # 如果是编辑模式，填充数据
        if template:
            self.fill_data()
    
    def create_ui(self):
        """创建用户界面"""
        main_frame = ttk.Frame(self.window, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 基本信息
        info_frame = ttk.LabelFrame(main_frame, text="基本信息", padding="10")
        info_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(info_frame, text="模板名称：").grid(row=0, column=0, sticky=tk.W)
        self.name_entry = ttk.Entry(info_frame)
        self.name_entry.grid(row=0, column=1, sticky=tk.EW, padx=(5, 0))
        
        ttk.Label(info_frame, text="标签宽度：").grid(row=1, column=0, sticky=tk.W, pady=(5, 0))
        self.width_entry = ttk.Entry(info_frame)
        self.width_entry.grid(row=1, column=1, sticky=tk.EW, padx=(5, 0), pady=(5, 0))
        self.width_entry.insert(0, "400")
        
        ttk.Label(info_frame, text="标签高度：").grid(row=2, column=0, sticky=tk.W, pady=(5, 0))
        self.height_entry = ttk.Entry(info_frame)
        self.height_entry.grid(row=2, column=1, sticky=tk.EW, padx=(5, 0), pady=(5, 0))
        self.height_entry.insert(0, "200")
        
        ttk.Label(info_frame, text="校验字段：").grid(row=3, column=0, sticky=tk.W, pady=(5, 0))
        self.key_field_combo = ttk.Combobox(info_frame, state="readonly")
        self.key_field_combo.grid(row=3, column=1, sticky=tk.EW, padx=(5, 0), pady=(5, 0))
        
        info_frame.columnconfigure(1, weight=1)
        
        # 字段定义
        fields_frame = ttk.LabelFrame(main_frame, text="字段定义", padding="10")
        fields_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        # 字段列表
        self.fields_tree = ttk.Treeview(fields_frame, columns=("name", "default"), show="headings")
        self.fields_tree.heading("name", text="字段名称")
        self.fields_tree.heading("default", text="默认值")
        self.fields_tree.pack(fill=tk.BOTH, expand=True)
        
        # 字段操作按钮
        field_btn_frame = ttk.Frame(fields_frame)
        field_btn_frame.pack(fill=tk.X, pady=(5, 0))
        
        ttk.Button(field_btn_frame, text="添加字段", command=self.add_field).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(field_btn_frame, text="编辑字段", command=self.edit_field).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(field_btn_frame, text="删除字段", command=self.delete_field).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(field_btn_frame, text="上移", command=self.move_field_up).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(field_btn_frame, text="下移", command=self.move_field_down).pack(side=tk.LEFT)
        
        # 模板内容
        content_frame = ttk.LabelFrame(main_frame, text="模板内容（使用 {字段名} 作为占位符）", padding="10")
        content_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.content_text = tk.Text(content_frame, height=5)
        self.content_text.pack(fill=tk.X)
        
        # 按钮区域
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(fill=tk.X)
        
        ttk.Button(btn_frame, text="保存", command=self.save).pack(side=tk.RIGHT, padx=(5, 0))
        ttk.Button(btn_frame, text="取消", command=self.cancel).pack(side=tk.RIGHT)
        
        # 刷新字段列表
        self.refresh_fields()
    
    def fill_data(self):
        """填充数据"""
        self.name_entry.insert(0, self.template.name)
        self.width_entry.delete(0, tk.END)
        self.width_entry.insert(0, str(self.template.width))
        self.height_entry.delete(0, tk.END)
        self.height_entry.insert(0, str(self.template.height))
        self.content_text.insert("1.0", self.template.content)
        
        # 设置校验字段
        field_names = [f['name'] for f in self.template.fields]
        self.key_field_combo['values'] = field_names
        if self.template.key_field and self.template.key_field in field_names:
            self.key_field_combo.set(self.template.key_field)
    
    def refresh_fields(self):
        """刷新字段列表"""
        for item in self.fields_tree.get_children():
            self.fields_tree.delete(item)
        
        for field in self.fields:
            self.fields_tree.insert('', tk.END, values=(field['name'], field.get('default', '')))
        
        # 更新校验字段下拉框
        field_names = [f['name'] for f in self.fields]
        self.key_field_combo['values'] = field_names
    
    def add_field(self):
        """添加字段"""
        FieldEditWindow(self.window, None, self.on_field_saved)
    
    def edit_field(self):
        """编辑字段"""
        selection = self.fields_tree.selection()
        if not selection:
            messagebox.showwarning("警告", "请选择要编辑的字段")
            return
        
        item = self.fields_tree.item(selection[0])
        field_name = item['values'][0]
        field = next((f for f in self.fields if f['name'] == field_name), None)
        
        if field:
            FieldEditWindow(self.window, field, self.on_field_saved)
    
    def delete_field(self):
        """删除字段"""
        selection = self.fields_tree.selection()
        if not selection:
            messagebox.showwarning("警告", "请选择要删除的字段")
            return
        
        item = self.fields_tree.item(selection[0])
        field_name = item['values'][0]
        
        if messagebox.askyesno("确认", f"确定要删除字段 '{field_name}' 吗？"):
            self.fields = [f for f in self.fields if f['name'] != field_name]
            self.refresh_fields()
    
    def move_field_up(self):
        """上移字段"""
        selection = self.fields_tree.selection()
        if not selection:
            return
        
        item = self.fields_tree.item(selection[0])
        field_name = item['values'][0]
        idx = next((i for i, f in enumerate(self.fields) if f['name'] == field_name), None)
        
        if idx and idx > 0:
            self.fields[idx], self.fields[idx-1] = self.fields[idx-1], self.fields[idx]
            self.refresh_fields()
    
    def move_field_down(self):
        """下移字段"""
        selection = self.fields_tree.selection()
        if not selection:
            return
        
        item = self.fields_tree.item(selection[0])
        field_name = item['values'][0]
        idx = next((i for i, f in enumerate(self.fields) if f['name'] == field_name), None)
        
        if idx is not None and idx < len(self.fields) - 1:
            self.fields[idx], self.fields[idx+1] = self.fields[idx+1], self.fields[idx]
            self.refresh_fields()
    
    def on_field_saved(self, field):
        """字段保存回调"""
        existing = next((i for i, f in enumerate(self.fields) if f['name'] == field['name']), None)
        if existing is not None:
            self.fields[existing] = field
        else:
            self.fields.append(field)
        
        self.refresh_fields()
    
    def save(self):
        """保存模板"""
        name = self.name_entry.get().strip()
        if not name:
            messagebox.showwarning("警告", "请输入模板名称")
            return
        
        try:
            width = int(self.width_entry.get())
            height = int(self.height_entry.get())
        except ValueError:
            messagebox.showwarning("警告", "宽度和高度必须是数字")
            return
        
        content = self.content_text.get("1.0", tk.END).strip()
        key_field = self.key_field_combo.get() or None
        
        template = LabelTemplate(
            name=name,
            width=width,
            height=height,
            fields=self.fields,
            content=content,
            key_field=key_field
        )
        
        self.callback(template)
        self.window.destroy()
    
    def cancel(self):
        """取消"""
        self.window.destroy()


class FieldEditWindow:
    """字段编辑窗口"""
    
    def __init__(self, parent, field, callback):
        self.parent = parent
        self.field = field
        self.callback = callback
        
        # 创建窗口
        self.window = tk.Toplevel(parent)
        self.window.title("编辑字段" if field else "添加字段")
        self.window.geometry("300x150")
        self.window.transient(parent)
        self.window.grab_set()
        
        # 创建UI
        self.create_ui()
        
        # 如果是编辑模式，填充数据
        if field:
            self.fill_data()
    
    def create_ui(self):
        """创建用户界面"""
        main_frame = ttk.Frame(self.window, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        ttk.Label(main_frame, text="字段名称：").grid(row=0, column=0, sticky=tk.W)
        self.name_entry = ttk.Entry(main_frame)
        self.name_entry.grid(row=0, column=1, sticky=tk.EW, padx=(5, 0))
        
        ttk.Label(main_frame, text="默认值：").grid(row=1, column=0, sticky=tk.W, pady=(5, 0))
        self.default_entry = ttk.Entry(main_frame)
        self.default_entry.grid(row=1, column=1, sticky=tk.EW, padx=(5, 0), pady=(5, 0))
        
        main_frame.columnconfigure(1, weight=1)
        
        # 按钮区域
        btn_frame = ttk.Frame(main_frame)
        btn_frame.grid(row=2, column=0, columnspan=2, pady=(10, 0))
        
        ttk.Button(btn_frame, text="保存", command=self.save).pack(side=tk.RIGHT, padx=(5, 0))
        ttk.Button(btn_frame, text="取消", command=self.cancel).pack(side=tk.RIGHT)
    
    def fill_data(self):
        """填充数据"""
        self.name_entry.insert(0, self.field['name'])
        self.default_entry.insert(0, self.field.get('default', ''))
    
    def save(self):
        """保存字段"""
        name = self.name_entry.get().strip()
        if not name:
            messagebox.showwarning("警告", "请输入字段名称")
            return
        
        field = {
            'name': name,
            'default': self.default_entry.get().strip()
        }
        
        self.callback(field)
        self.window.destroy()
    
    def cancel(self):
        """取消"""
        self.window.destroy()


def main():
    """主函数"""
    app = LabelPrintApp()
    app.run()


if __name__ == "__main__":
    main()
