/**
 * DVBBS 8.3 Markdown编辑器（使用官方marked.js）
 * 版本: 2.0 - 官方库版本
 * 依赖: marked.min.js
 */

(function() {
    'use strict';

    // 检查marked.js是否已加载
    if (typeof marked === 'undefined') {
        console.error('错误：marked.js未加载，请先引入 marked.min.js');
        console.error('下载地址：https://cdn.jsdelivr.net/npm/marked/marked.min.js');
        return;
    }

    // 配置marked选项
    marked.setOptions({
        gfm: true,              // 启用GitHub风格Markdown
        breaks: true,           // 转换换行符为<br>
        pedantic: false,        // 不使用原始markdown.pl风格
        sanitize: false,        // 我们自己处理安全过滤
        smartLists: true,       // 智能列表
        smartypants: false,     // 不使用智能标点
        xhtml: false            // 不输出自闭合标签
    });

    // 安全过滤函数
    function sanitizeHtml(html) {
        // 移除危险标签
        html = html.replace(/<script[^>]*?>.*?<\/script>/gi, '');
        html = html.replace(/<iframe[^>]*?>.*?<\/iframe>/gi, '');
        html = html.replace(/<object[^>]*?>.*?<\/object>/gi, '');
        html = html.replace(/<embed[^>]*?>/gi, '');
        html = html.replace(/<applet[^>]*?>.*?<\/applet>/gi, '');

        // 移除危险属性
        html = html.replace(/\son\w+\s*=\s*["'][^"']*["']/gi, '');
        html = html.replace(/javascript:/gi, '');
        html = html.replace(/vbscript:/gi, '');
        html = html.replace(/data:text\/html/gi, '');

        return html;
    }

    // Markdown编辑器类
    function MarkdownEditor(options) {
        this.textarea = options.textarea;
        this.preview = options.preview;
        this.toolbar = options.toolbar;
        this.enablePreview = options.enablePreview !== false;
        this.init();
    }

    MarkdownEditor.prototype = {
        init: function() {
            this.createToolbar();
            this.bindEvents();
            if (this.enablePreview) {
                this.updatePreview();
            }
            console.log('✅ Markdown编辑器初始化完成（使用marked.js）');
        },

        createToolbar: function() {
            if (!this.toolbar) return;

            var tools = [
                { name: 'bold', icon: 'B', title: '粗体 (Ctrl+B)', action: this.bold },
                { name: 'italic', icon: 'I', title: '斜体 (Ctrl+I)', action: this.italic },
                { name: 'strike', icon: 'S', title: '删除线', action: this.strikethrough },
                { name: 'separator', type: 'separator' },
                { name: 'h1', icon: 'H1', title: '一级标题', action: this.heading1 },
                { name: 'h2', icon: 'H2', title: '二级标题', action: this.heading2 },
                { name: 'h3', icon: 'H3', title: '三级标题', action: this.heading3 },
                { name: 'separator', type: 'separator' },
                { name: 'link', icon: '🔗', title: '插入链接 (Ctrl+K)', action: this.link },
                { name: 'image', icon: '🖼', title: '插入图片', action: this.image },
                { name: 'code', icon: '<>', title: '代码块', action: this.codeblock },
                { name: 'separator', type: 'separator' },
                { name: 'ul', icon: '•', title: '无序列表', action: this.unorderedList },
                { name: 'ol', icon: '1.', title: '有序列表', action: this.orderedList },
                { name: 'quote', icon: '"', title: '引用', action: this.quote },
                { name: 'table', icon: '⊞', title: '插入表格', action: this.table },
                { name: 'separator', type: 'separator' },
                { name: 'preview', icon: '👁', title: '切换预览', action: this.togglePreview }
            ];

            var toolbarHtml = '<div class="md-toolbar">';
            for (var i = 0; i < tools.length; i++) {
                var tool = tools[i];
                if (tool.type === 'separator') {
                    toolbarHtml += '<span class="md-separator">|</span>';
                } else {
                    toolbarHtml += '<button type="button" class="md-btn" data-action="' + tool.name + '" title="' + tool.title + '">' + tool.icon + '</button>';
                }
            }
            toolbarHtml += '</div>';

            this.toolbar.innerHTML = toolbarHtml;
        },

        bindEvents: function() {
            var self = this;

            // 工具栏点击
            if (this.toolbar) {
                this.toolbar.addEventListener('click', function(e) {
                    if (e.target.classList.contains('md-btn')) {
                        var action = e.target.getAttribute('data-action');
                        self[action].call(self);
                        e.preventDefault();
                    }
                });
            }

            // 实时预览
            if (this.enablePreview && this.preview) {
                this.textarea.addEventListener('input', function() {
                    self.updatePreview();
                });
            }

            // 快捷键
            this.textarea.addEventListener('keydown', function(e) {
                if (e.ctrlKey || e.metaKey) {
                    switch(e.keyCode) {
                        case 66: // Ctrl+B
                            e.preventDefault();
                            self.bold();
                            break;
                        case 73: // Ctrl+I
                            e.preventDefault();
                            self.italic();
                            break;
                        case 75: // Ctrl+K
                            e.preventDefault();
                            self.link();
                            break;
                    }
                }

                if (e.keyCode === 9) { // Tab
                    e.preventDefault();
                    self.insertText('    ');
                }
            });
        },

        getSelection: function() {
            var start = this.textarea.selectionStart;
            var end = this.textarea.selectionEnd;
            return {
                start: start,
                end: end,
                text: this.textarea.value.substring(start, end)
            };
        },

        insertText: function(before, after, defaultText) {
            var selection = this.getSelection();
            var text = selection.text || defaultText || '';
            var newText = before + text + (after || '');

            this.textarea.value = this.textarea.value.substring(0, selection.start) +
                                  newText +
                                  this.textarea.value.substring(selection.end);

            var cursorPos = selection.start + before.length + text.length;
            this.textarea.setSelectionRange(cursorPos, cursorPos);
            this.textarea.focus();

            if (this.enablePreview) {
                this.updatePreview();
            }
        },

        replaceLine: function(prefix) {
            var selection = this.getSelection();
            var value = this.textarea.value;
            var lineStart = value.lastIndexOf('\n', selection.start - 1) + 1;
            var lineEnd = value.indexOf('\n', selection.end);
            if (lineEnd === -1) lineEnd = value.length;

            var line = value.substring(lineStart, lineEnd);
            var newLine = prefix + line.replace(/^#+\s*/, '');

            this.textarea.value = value.substring(0, lineStart) +
                                  newLine +
                                  value.substring(lineEnd);

            this.textarea.setSelectionRange(lineStart + prefix.length, lineStart + newLine.length);
            this.textarea.focus();

            if (this.enablePreview) {
                this.updatePreview();
            }
        },

        // 工具栏功能
        bold: function() {
            this.insertText('**', '**', '粗体文本');
        },

        italic: function() {
            this.insertText('*', '*', '斜体文本');
        },

        strikethrough: function() {
            this.insertText('~~', '~~', '删除线文本');
        },

        heading1: function() {
            this.replaceLine('# ');
        },

        heading2: function() {
            this.replaceLine('## ');
        },

        heading3: function() {
            this.replaceLine('### ');
        },

        link: function() {
            var url = prompt('请输入链接地址:', 'https://');
            if (url) {
                this.insertText('[', '](' + url + ')', '链接文本');
            }
        },

        image: function() {
            var url = prompt('请输入图片地址:', 'https://');
            if (url) {
                this.insertText('![', '](' + url + ')', '图片描述');
            }
        },

        codeblock: function() {
            var lang = prompt('请输入代码语言 (如: javascript, python):', 'javascript');
            this.insertText('```' + (lang || '') + '\n', '\n```', '代码内容');
        },

        unorderedList: function() {
            this.replaceLine('- ');
        },

        orderedList: function() {
            this.replaceLine('1. ');
        },

        quote: function() {
            this.replaceLine('> ');
        },

        table: function() {
            var tableTemplate = '\n| 列1 | 列2 | 列3 |\n| --- | --- | --- |\n| 内容1 | 内容2 | 内容3 |\n';
            this.insertText(tableTemplate);
        },

        togglePreview: function() {
            if (!this.preview) return;

            if (this.preview.style.display === 'none') {
                this.preview.style.display = 'block';
                this.updatePreview();
            } else {
                this.preview.style.display = 'none';
            }
        },

        // 使用marked.js更新预览
        updatePreview: function() {
            if (!this.preview) return;

            var markdown = this.textarea.value;

            // 使用marked.js解析
            var html = marked.parse(markdown);

            // 安全过滤
            html = sanitizeHtml(html);

            this.preview.innerHTML = html;

            // 代码高亮
            if (typeof hljs !== 'undefined') {
                this.preview.querySelectorAll('pre code').forEach(function(block) {
                    hljs.highlightBlock(block);
                });
            }
        }
    };

    // 导出
    window.MarkdownEditor = MarkdownEditor;

    // 自动初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initMarkdownEditors);
    } else {
        initMarkdownEditors();
    }

    function initMarkdownEditors() {
        var textareas = document.querySelectorAll('.markdown-editor');
        for (var i = 0; i < textareas.length; i++) {
            var textarea = textareas[i];
            var wrapper = textarea.parentElement;

            var toolbar = document.createElement('div');
            toolbar.className = 'markdown-toolbar';
            wrapper.insertBefore(toolbar, textarea);

            var preview = document.createElement('div');
            preview.className = 'markdown-preview';
            preview.style.display = 'none';
            wrapper.appendChild(preview);

            new MarkdownEditor({
                textarea: textarea,
                toolbar: toolbar,
                preview: preview,
                enablePreview: true
            });
        }
    }
})();
