// JavaScript для веб-приложения Bubble Tea "BibaBobaBebe"

document.addEventListener('DOMContentLoaded', function() {
    // Автоматическое закрытие алертов через 5 секунд
    const alerts = document.querySelectorAll('.alert:not(.alert-permanent)');
    alerts.forEach(alert => {
        setTimeout(() => {
            const bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        }, 5000);
    });

    // Подтверждение перед удалением
    const deleteButtons = document.querySelectorAll('.btn-delete');
    deleteButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            if (!confirm('Вы уверены, что хотите удалить этот элемент?')) {
                e.preventDefault();
            }
        });
    });

    // Анимация чисел (для счетчиков)
    const animateValue = (element, start, end, duration) => {
        let startTimestamp = null;
        const step = (timestamp) => {
            if (!startTimestamp) startTimestamp = timestamp;
            const progress = Math.min((timestamp - startTimestamp) / duration, 1);
            element.innerHTML = Math.floor(progress * (end - start) + start);
            if (progress < 1) {
                window.requestAnimationFrame(step);
            }
        };
        window.requestAnimationFrame(step);
    };

    // Инициализация анимации счетчиков
    const counters = document.querySelectorAll('[data-counter]');
    counters.forEach(counter => {
        const target = parseInt(counter.getAttribute('data-counter'));
        animateValue(counter, 0, target, 2000);
    });

    // Валидация форм
    const forms = document.querySelectorAll('.needs-validation');
    forms.forEach(form => {
        form.addEventListener('submit', function(event) {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
            }
            form.classList.add('was-validated');
        }, false);
    });

    // Поиск в таблицах
    const searchInputs = document.querySelectorAll('[data-table-search]');
    searchInputs.forEach(input => {
        input.addEventListener('keyup', function() {
            const tableId = this.getAttribute('data-table-search');
            const table = document.getElementById(tableId);
            const filter = this.value.toLowerCase();
            const rows = table.querySelectorAll('tbody tr');

            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(filter) ? '' : 'none';
            });
        });
    });

    // Tooltips Bootstrap
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function(tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Popovers Bootstrap
    const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    popoverTriggerList.map(function(popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Форматирование номера телефона
    const phoneInputs = document.querySelectorAll('input[type="tel"]');
    phoneInputs.forEach(input => {
        input.addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            if (value.length > 0) {
                if (value.length <= 1) {
                    value = '+7';
                } else if (value.length <= 4) {
                    value = '+7-' + value.slice(1);
                } else if (value.length <= 7) {
                    value = '+7-' + value.slice(1, 4) + '-' + value.slice(4);
                } else if (value.length <= 9) {
                    value = '+7-' + value.slice(1, 4) + '-' + value.slice(4, 7) + '-' + value.slice(7);
                } else {
                    value = '+7-' + value.slice(1, 4) + '-' + value.slice(4, 7) + '-' + value.slice(7, 11);
                }
            }
            e.target.value = value;
        });
    });

    // Фильтр продуктов по категориям (если есть)
    const categoryFilters = document.querySelectorAll('[data-category-filter]');
    categoryFilters.forEach(filter => {
        filter.addEventListener('click', function(e) {
            e.preventDefault();
            const category = this.getAttribute('data-category-filter');
            const products = document.querySelectorAll('[data-product-category]');

            products.forEach(product => {
                const productCategory = product.getAttribute('data-product-category');
                if (category === 'all' || productCategory === category) {
                    product.style.display = '';
                } else {
                    product.style.display = 'none';
                }
            });

            // Обновление активного фильтра
            categoryFilters.forEach(f => f.classList.remove('active'));
            this.classList.add('active');
        });
    });

    // Печать страницы
    const printButtons = document.querySelectorAll('[data-print]');
    printButtons.forEach(button => {
        button.addEventListener('click', function() {
            window.print();
        });
    });

    // Копирование в буфер обмена
    const copyButtons = document.querySelectorAll('[data-copy]');
    copyButtons.forEach(button => {
        button.addEventListener('click', function() {
            const text = this.getAttribute('data-copy');
            navigator.clipboard.writeText(text).then(() => {
                // Показываем уведомление
                const originalText = this.innerHTML;
                this.innerHTML = '<i class="bi bi-check"></i> Скопировано!';
                setTimeout(() => {
                    this.innerHTML = originalText;
                }, 2000);
            });
        });
    });

    // Обновление времени
    const updateTime = () => {
        const timeElements = document.querySelectorAll('[data-realtime]');
        timeElements.forEach(element => {
            const now = new Date();
            element.textContent = now.toLocaleString('ru-RU', {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });
        });
    };
    setInterval(updateTime, 1000);

    // Плавная прокрутка к элементам
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                e.preventDefault();
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Отслеживание изменений в форме (предупреждение перед уходом)
    const trackedForms = document.querySelectorAll('[data-track-changes]');
    let formChanged = false;

    trackedForms.forEach(form => {
        form.addEventListener('change', function() {
            formChanged = true;
        });

        form.addEventListener('submit', function() {
            formChanged = false;
        });
    });

    window.addEventListener('beforeunload', function(e) {
        if (formChanged) {
            e.preventDefault();
            e.returnValue = '';
            return '';
        }
    });

    // Автосохранение данных формы в localStorage
    const autosaveForms = document.querySelectorAll('[data-autosave]');
    autosaveForms.forEach(form => {
        const formId = form.getAttribute('data-autosave');
        
        // Загрузка сохраненных данных
        const savedData = localStorage.getItem(`form_${formId}`);
        if (savedData) {
            const data = JSON.parse(savedData);
            Object.keys(data).forEach(key => {
                const input = form.querySelector(`[name="${key}"]`);
                if (input) input.value = data[key];
            });
        }

        // Сохранение при изменении
        form.addEventListener('input', function() {
            const formData = {};
            const inputs = form.querySelectorAll('input, textarea, select');
            inputs.forEach(input => {
                if (input.name) {
                    formData[input.name] = input.value;
                }
            });
            localStorage.setItem(`form_${formId}`, JSON.stringify(formData));
        });

        // Очистка при отправке
        form.addEventListener('submit', function() {
            localStorage.removeItem(`form_${formId}`);
        });
    });

    console.log('🧋 Bubble Tea "BibaBobaBebe" - приложение загружено!');
});

// Утилиты
const BubbleTea = {
    // Форматирование валюты
    formatCurrency: function(amount) {
        return new Intl.NumberFormat('ru-RU', {
            style: 'currency',
            currency: 'RUB'
        }).format(amount);
    },

    // Показать уведомление
    showNotification: function(message, type = 'info') {
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
        alertDiv.setAttribute('role', 'alert');
        alertDiv.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        const container = document.querySelector('.container');
        if (container) {
            container.insertBefore(alertDiv, container.firstChild);
            setTimeout(() => {
                alertDiv.remove();
            }, 5000);
        }
    },

    // AJAX запрос
    request: async function(url, options = {}) {
        try {
            const response = await fetch(url, {
                ...options,
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                }
            });
            return await response.json();
        } catch (error) {
            console.error('Request error:', error);
            this.showNotification('Ошибка при выполнении запроса', 'danger');
            throw error;
        }
    }
};

// Экспорт для использования в других скриптах
window.BubbleTea = BubbleTea;

