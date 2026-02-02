// OpenClawKit Main JavaScript

// Load Lemonsqueezy script
function loadLemonsqueezy() {
    if (window.createLemonSqueezy) {
        window.createLemonSqueezy();
    } else {
        const script = document.createElement('script');
        script.src = 'https://assets.lemonsqueezy.com/lemon.js';
        script.onload = function() {
            window.createLemonSqueezy();
        };
        document.head.appendChild(script);
    }
}

// Wait for DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    // Load Lemonsqueezy
    loadLemonsqueezy();
    
    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            // Don't prevent default for Lemonsqueezy links
            if (this.id === 'lemon-button') return;
            
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            
            // Skip if it's just "#" (empty anchor)
            if(targetId === "#") return;
            
            const targetElement = document.querySelector(targetId);
            
            if(targetElement) {
                window.scrollTo({
                    top: targetElement.offsetTop - 80,
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Email tracking for Lemonsqueezy
    const emailInput = document.getElementById('email');
    const lemmonButton = document.getElementById('lemon-button');
    if (emailInput && lemmonButton) {
        emailInput.addEventListener('change', function() {
            // Store email for reference (Lemonsqueezy handles this in checkout)
            if (this.value) {
                // Update button data if needed
                lemmonButton.dataset.email = this.value;
            }
        });
    }
    
    // Newsletter checkbox tracking
    const newsletterCheckbox = document.getElementById('newsletter');
    if (newsletterCheckbox) {
        newsletterCheckbox.addEventListener('change', function() {
            // Store preference (can be used for post-purchase handling)
            console.log('Newsletter subscription:', this.checked);
        });
    }
    
    // Form submission handling for free guide form
    const guideForm = document.getElementById('guide-form');
    if(guideForm) {
        guideForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const email = guideForm.querySelector('input[type="email"]').value;
            const button = guideForm.querySelector('button[type="submit"]');
            const originalText = button.innerHTML;
            
            button.disabled = true;
            button.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Sending...';
            
            // Simulate API call delay
            setTimeout(() => {
                guideForm.innerHTML = `
                    <div class="alert alert-success">
                        <strong>Success!</strong> Your free guide has been sent to <strong>${email}</strong>.
                        Please check your inbox (and spam folder) for the download link.
                    </div>
                `;
            }, 1500);
        });
    }
    
    // Navbar background change on scroll
    const navbar = document.querySelector('.navbar');
    if(navbar) {
        window.addEventListener('scroll', () => {
            if(window.scrollY > 50) {
                navbar.classList.add('navbar-scrolled');
            } else {
                navbar.classList.remove('navbar-scrolled');
            }
        });
    }
});

// Simulated Stripe integration (in a real app, this would use the Stripe JS SDK)
// This is just for demonstration purposes
function initStripe() {
    // This would normally initialize Stripe elements
    console.log('Stripe initialized');
}

// Call simulated init
initStripe();