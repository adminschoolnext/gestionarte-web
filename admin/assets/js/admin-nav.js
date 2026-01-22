// ==========================================
// ADMIN NAVIGATION - Menú Dinámico
// ==========================================
// Este script carga el menú desde menu-config.json
// y lo renderiza automáticamente en todas las páginas
// ==========================================

class AdminNavigation {
    constructor() {
        // Obtener el nombre del archivo actual (ej: "clientes.html")
        this.currentPage = window.location.pathname.split('/').pop();
        this.menuContainer = null;
        this.menuConfig = null;
    }
    
    /**
     * Inicializa el menú: carga configuración y renderiza
     */
    async init() {
        try {
            await this.loadMenuConfig();
            this.render();
            this.setActivePage();
        } catch (error) {
            console.error('Error inicializando menú de navegación:', error);
            this.renderFallback();
        }
    }
    
    /**
     * Carga la configuración del menú desde JSON
     */
    async loadMenuConfig() {
        try {
            // Intentar cargar desde assets/js/menu-config.json
            const response = await fetch('assets/js/menu-config.json');
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            this.menuConfig = await response.json();
            console.log('✅ Configuración del menú cargada:', this.menuConfig.menuItems.length, 'ítems');
        } catch (error) {
            console.error('❌ Error cargando menu-config.json:', error);
            throw error;
        }
    }
    
    /**
     * Renderiza el menú en el DOM
     */
    render() {
        this.menuContainer = document.getElementById('admin-sidebar');
        
        if (!this.menuContainer) {
            console.warn('⚠️ No se encontró elemento con id="admin-sidebar"');
            return;
        }
        
        // Ordenar ítems por el campo "order"
        const sortedItems = this.menuConfig.menuItems.sort((a, b) => a.order - b.order);
        
        // Generar HTML del menú
        const html = sortedItems.map(item => this.renderMenuItem(item)).join('');
        
        this.menuContainer.innerHTML = html;
        
        console.log('✅ Menú renderizado con', sortedItems.length, 'ítems');
    }
    
    /**
     * Renderiza un ítem individual del menú
     */
    renderMenuItem(item) {
        const badgeHTML = item.badge 
            ? `<span class="menu-badge">${item.badge}</span>` 
            : '';
        
        return `
            <a href="${item.url}" 
               class="nav-item" 
               data-page="${item.id}"
               title="${item.label}">
                <i class="bi ${item.icon}"></i> 
                ${item.label}
                ${badgeHTML}
            </a>
        `;
    }
    
    /**
     * Marca como activa la página actual
     */
    setActivePage() {
        const navItems = document.querySelectorAll('.nav-item');
        
        navItems.forEach(item => {
            const itemUrl = item.getAttribute('href');
            
            // Comparar con la página actual
            if (itemUrl === this.currentPage) {
                item.classList.add('active');
                console.log('✅ Página activa:', this.currentPage);
            }
        });
    }
    
    /**
     * Renderiza un menú de respaldo si falla la carga
     */
    renderFallback() {
        console.warn('⚠️ Usando menú de respaldo (fallback)');
        
        this.menuContainer = document.getElementById('admin-sidebar');
        if (!this.menuContainer) return;
        
        // Menú mínimo hardcodeado como respaldo
        this.menuContainer.innerHTML = `
            <a href="index.html" class="nav-item">
                <i class="bi bi-speedometer2"></i> Dashboard
            </a>
            <a href="clientes.html" class="nav-item">
                <i class="bi bi-building"></i> Clientes
            </a>
            <a href="configuracion.html" class="nav-item">
                <i class="bi bi-sliders"></i> Configuración
            </a>
        `;
        
        this.setActivePage();
    }
}

// ==========================================
// AUTO-INICIALIZACIÓN
// ==========================================
// Se ejecuta automáticamente cuando el DOM está listo
document.addEventListener('DOMContentLoaded', () => {
    const nav = new AdminNavigation();
    nav.init();
});

// Exportar para uso opcional en otros scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AdminNavigation;
}
