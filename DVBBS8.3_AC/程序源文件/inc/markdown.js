/**
 * DVBBS 8.3 Markdown编辑器
 * 版本: 1.0
 * 日期: 2024-06-24
 * 功能: Markdown实时预览、工具栏、语法高亮
 */

(function() {
    'use strict';

    // Markdown编辑器类
    function MarkdownEditor(options) {
        this.textarea = options.textarea;
        this.preview = options.preview;
        this.toolbar = options.toolbar;
        this.enablePreview = options.enablePreview !== false;
        this.init();
    }

    MarkdownEditor.prototype = {
        // 初始化编辑器
        init: function() {
            this.createToolbar();
            this.bindEvents();
            if (this.enablePreview) {
                this.updatePreview();
            }
        },

        // 创建工具栏
        createToolbar: function() {
            if (!this.toolbar) return;

            var tools = [
                { name: 'bold', icon: 'B', title: '粗体', action: this.bold },
                { name: 'italic', icon: 'I', title: '斜体', action: this.italic },
                { name: 'strike', icon: 'S', title: '删除线', action: this.strikethrough },
                { name: 'separator', type: 'separator' },
                { name: 'h1', icon: 'H1', title: '一级标题', action: this.heading1 },
                { name: 'h2', icon: 'H2', title: '二级标题', action: this.heading2 },
                { name: 'h3', icon: 'H3', title: '三级标题', action: this.heading3 },
                { name: 'separator', type: 'separator' },
                { name: 'link', icon: '🔗', title: '插入链接', action: this.link },
                { name: 'image', icon: '🖼', title: '插入图片', action: this.image },
                { name: 'code', icon: '<>', title: '代码块', action: this.codeblock },
                { name: 'separator', type: 'separator' },
                { name: 'ul', icon: '•', title: '无序列表', action: this.unorderedList },
                { name: 'ol', icon: '1.', title: '有序列表', action: this.orderedList },
                { name: 'quote', icon: '"', title: '引用', action: this.quote },
                { name: 'separator', type: 'separator' },
                { name: 'preview', icon: '👁', title: '预览', action: this.togglePreview }
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

        // 绑定事件
        bindEvents: function() {
            var self = this;

            // 工具栏按钮点击事件
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

            // Tab键支持
            this.textarea.addEventListener('keydown', function(e) {
                if (e.keyCode === 9) { // Tab键
                    e.preventDefault();
                    self.insertText('    ');
                }
            });
        },

        // 获取选中文本
        getSelection: function() {
            var start = this.textarea.selectionStart;
            var end = this.textarea.selectionEnd;
            return {
                start: start,
                end: end,
                text: this.textarea.value.substring(start, end)
            };
        },

        // 插入文本
        insertText: function(before, after, defaultText) {
            var selection = this.getSelection();
            var text = selection.text || defaultText || '';
            var newText = before + text + (after || '');

            this.textarea.value = this.textarea.value.substring(0, selection.start) +
                                  newText +
                                  this.textarea.value.substring(selection.end);

            // 设置光标位置
            var cursorPos = selection.start + before.length + text.length;
            this.textarea.setSelectionRange(cursorPos, cursorPos);
            this.textarea.focus();

            if (this.enablePreview) {
                this.updatePreview();
            }
        },

        // 替换行
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

        // 工具栏功能实现
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
            this.insertText('```\n', '\n```', '代码内容');
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

        togglePreview: function() {
            if (!this.preview) return;

            if (this.preview.style.display === 'none') {
                this.preview.style.display = 'block';
                this.updatePreview();
            } else {
                this.preview.style.display = 'none';
            }
        },

        // 更新预览
        updatePreview: function() {
            if (!this.preview) return;

            var markdown = this.textarea.value;
            var html = this.parseMarkdown(markdown);
            this.preview.innerHTML = html;

            // 代码高亮（如果引入了highlight.js）
            if (typeof hljs !== 'undefined') {
                this.preview.querySelectorAll('pre code').forEach(function(block) {
                    hljs.highlightBlock(block);
                });
            }
        },

        // 简单的Markdown解析器（客户端版本）
        parseMarkdown: function(markdown) {
            var html = markdown;

            // 转义HTML
            html = html.replace(/&/g, '&amp;')
                       .replace(/</g, '&lt;')
                       .replace(/>/g, '&gt;')
                       .replace(/"/g, '&quot;');

            // 代码块
            html = html.replace(/```(\w*)\n([\s\S]*?)\n```/g, function(match, lang, code) {
                return '<pre><code class="language-' + (lang || 'text') + '">' + code + '</code></pre>';
            });

            // 行内代码
            html = html.replace(/`([^`]+)`/g, '<code>$1</code>');

            // 标题
            html = html.replace(/^######\s+(.+)$/gm, '<h6>$1</h6>');
            html = html.replace(/^#####\s+(.+)$/gm, '<h5>$1</h5>');
            html = html.replace(/^####\s+(.+)$/gm, '<h4>$1</h4>');
            html = html.replace(/^###\s+(.+)$/gm, '<h3>$1</h3>');
            html = html.replace(/^##\s+(.+)$/gm, '<h2>$1</h2>');
            html = html.replace(/^#\s+(.+)$/gm, '<h1>$1</h1>');

            // 水平线
            html = html.replace(/^(\*\*\*|---|___)$/gm, '<hr />');

            // 图片
            html = html.replace(/!\[([^\]]*)\]\(([^\)]+)\)/g, '<img src="$2" alt="$1" />');

            // 链接
            html = html.replace(/\[([^\]]+)\]\(([^\)]+)\)/g, '<a href="$2" target="_blank">$1</a>');

            // 粗体
            html = html.replace(/\*\*([^\*]+)\*\*/g, '<strong>$1</strong>');
            html = html.replace(/__([^_]+)__/g, '<strong>$1</strong>');

            // 斜体
            html = html.replace(/\*([^\*]+)\*/g, '<em>$1</em>');
            html = html.replace(/_([^_]+)_/g, '<em>$1</em>');

            // 删除线
            html = html.replace(/~~([^~]+)~~/g, '<del>$1</del>');

            // 引用
            html = html.replace(/^>\s+(.+)$/gm, '<blockquote>$1</blockquote>');

            // 列表
            html = html.replace(/^[\*\-\+]\s+(.+)$/gm, '<li>$1</li>');
            html = html.replace(/^\d+\.\s+(.+)$/gm, '<li>$1</li>');

            // 换行
            html = html.replace(/\n\n/g, '</p><p>');
            html = html.replace(/\n/g, '<br />');

            // 包装段落
            html = '<p>' + html + '</p>';

            return html;
        }
    };

    // 导出到全局
    window.MarkdownEditor = MarkdownEditor;

    // 页面加载完成后自动初始化
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

            // 创建工具栏容器
            var toolbar = document.createElement('div');
            toolbar.className = 'markdown-toolbar';
            wrapper.insertBefore(toolbar, textarea);

            // 创建预览容器
            var preview = document.createElement('div');
            preview.className = 'markdown-preview';
            preview.style.display = 'none';
            wrapper.appendChild(preview);

            // 初始化编辑器
            new MarkdownEditor({
                textarea: textarea,
                toolbar: toolbar,
                preview: preview,
                enablePreview: true
            });
        }
    }
})();
