/**
 * Highlight.js 精简版 - 内嵌代码高亮
 * 版本: 自定义精简版
 * 支持: JavaScript, HTML, CSS, Python, Java, C/C++, SQL, PHP
 */

(function() {
    'use strict';

    // 简化的语法高亮规则
    var languages = {
        javascript: {
            keywords: /\b(var|let|const|function|return|if|else|for|while|switch|case|break|continue|class|extends|import|export|default|async|await|try|catch|throw|new|this|typeof|instanceof)\b/g,
            string: /(["'`])(?:\\.|(?!\1)[^\\\r\n])*\1/g,
            comment: /(\/\/.*$|\/\*[\s\S]*?\*\/)/gm,
            number: /\b\d+(\.\d+)?\b/g,
            operator: /[+\-*/%=<>!&|^~?:]/g,
            function: /\b([a-zA-Z_$][\w$]*)\s*(?=\()/g
        },
        python: {
            keywords: /\b(def|class|import|from|as|if|elif|else|for|while|return|try|except|finally|with|lambda|yield|pass|break|continue|and|or|not|in|is|None|True|False)\b/g,
            string: /(["'])(?:\\.|(?!\1)[^\\\r\n])*\1/g,
            comment: /#.*$/gm,
            number: /\b\d+(\.\d+)?\b/g,
            decorator: /@\w+/g,
            function: /\b([a-zA-Z_][\w]*)\s*(?=\()/g
        },
        java: {
            keywords: /\b(public|private|protected|static|final|class|interface|extends|implements|void|int|String|boolean|long|double|float|char|return|if|else|for|while|switch|case|break|new|this|super|import|package|try|catch|throw|throws)\b/g,
            string: /(["'])(?:\\.|(?!\1)[^\\\r\n])*\1/g,
            comment: /(\/\/.*$|\/\*[\s\S]*?\*\/)/gm,
            number: /\b\d+(\.\d+)?[fFdDlL]?\b/g,
            annotation: /@\w+/g,
            function: /\b([a-zA-Z_][\w]*)\s*(?=\()/g
        },
        html: {
            tag: /<\/?[\w\-]+/g,
            attr: /[\w\-]+=(?:["'][^"']*["']|[\w\-]+)/g,
            string: /(["'])(?:\\.|(?!\1)[^\\\r\n])*\1/g,
            comment: /<!--[\s\S]*?-->/g
        },
        css: {
            selector: /[.#]?[\w\-]+(?=\s*\{)/g,
            property: /[\w\-]+(?=\s*:)/g,
            value: /:\s*([^;{}]+)/g,
            string: /(["'])(?:\\.|(?!\1)[^\\\r\n])*\1/g,
            comment: /\/\*[\s\S]*?\*\//g,
            important: /!important/g
        },
        sql: {
            keywords: /\b(SELECT|FROM|WHERE|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|TABLE|DATABASE|INDEX|VIEW|JOIN|LEFT|RIGHT|INNER|OUTER|ON|AND|OR|NOT|NULL|AS|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|UNION|DISTINCT)\b/gi,
            string: /(["'])(?:\\.|(?!\1)[^\\\r\n])*\1/g,
            comment: /(--.*$|\/\*[\s\S]*?\*\/)/gm,
            number: /\b\d+(\.\d+)?\b/g,
            function: /\b([a-zA-Z_][\w]*)\s*(?=\()/g
        },
        php: {
            keywords: /\b(function|return|if|else|elseif|endif|for|foreach|while|do|switch|case|break|continue|class|extends|public|private|protected|static|const|new|this|parent|self|try|catch|throw|namespace|use|require|include|echo|print|array|isset|empty|null|true|false)\b/g,
            variable: /\$[\w]+/g,
            string: /(["'])(?:\\.|(?!\1)[^\\\r\n])*\1/g,
            comment: /(\/\/.*$|\/\*[\s\S]*?\*\/|#.*$)/gm,
            number: /\b\d+(\.\d+)?\b/g,
            function: /\b([a-zA-Z_][\w]*)\s*(?=\()/g
        }
    };

    // 转义HTML
    function escapeHtml(text) {
        var map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.replace(/[&<>"']/g, function(m) { return map[m]; });
    }

    // 应用语法高亮
    function highlight(code, lang) {
        if (!lang || !languages[lang]) {
            return escapeHtml(code);
        }

        var rules = languages[lang];
        var highlighted = escapeHtml(code);

        // 保护已经高亮的部分
        var protectedParts = [];
        var protect = function(match) {
            var id = '___PROTECTED_' + protectedParts.length + '___';
            protectedParts.push(match);
            return id;
        };

        // 按优先级应用规则
        var order = ['comment', 'string', 'keywords', 'function', 'number', 'operator', 'tag', 'attr', 'property', 'value', 'variable', 'decorator', 'annotation', 'important'];

        order.forEach(function(type) {
            if (rules[type]) {
                highlighted = highlighted.replace(rules[type], function(match) {
                    if (match.indexOf('___PROTECTED_') === 0) {
                        return match;
                    }
                    return protect('<span class="hljs-' + type + '">' + match + '</span>');
                });
            }
        });

        // 恢复保护的部分
        protectedParts.forEach(function(part, index) {
            highlighted = highlighted.replace('___PROTECTED_' + index + '___', part);
        });

        return highlighted;
    }

    // 高亮所有代码块
    function highlightAll() {
        var blocks = document.querySelectorAll('pre code');
        blocks.forEach(function(block) {
            var lang = '';
            var classes = block.className.split(' ');

            // 查找语言类名
            for (var i = 0; i < classes.length; i++) {
                if (classes[i].indexOf('language-') === 0) {
                    lang = classes[i].replace('language-', '');
                    break;
                } else if (classes[i].indexOf('lang-') === 0) {
                    lang = classes[i].replace('lang-', '');
                    break;
                }
            }

            // 应用高亮
            var code = block.textContent || block.innerText;
            block.innerHTML = highlight(code, lang.toLowerCase());
            block.classList.add('hljs');
        });
    }

    // 单独高亮一个代码块
    function highlightBlock(block) {
        var lang = '';
        var classes = block.className.split(' ');

        for (var i = 0; i < classes.length; i++) {
            if (classes[i].indexOf('language-') === 0) {
                lang = classes[i].replace('language-', '');
                break;
            } else if (classes[i].indexOf('lang-') === 0) {
                lang = classes[i].replace('lang-', '');
                break;
            }
        }

        var code = block.textContent || block.innerText;
        block.innerHTML = highlight(code, lang.toLowerCase());
        block.classList.add('hljs');
    }

    // 导出API
    window.hljs = {
        highlightAll: highlightAll,
        highlightBlock: highlightBlock,
        highlight: function(code, options) {
            return highlight(code, options.language || '');
        }
    };

    // 自动初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', highlightAll);
    } else {
        highlightAll();
    }

})();
