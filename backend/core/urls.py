from django.contrib import admin
from django.urls import path
from django.conf import settings               # 👑 ADDED: To read MEDIA_URL and DEBUG from settings
from django.conf.urls.static import static     # 👑 ADDED: Helper function to serve static media files
from core import views  # 🚀 Clean, explicit import of your core app views!

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # All APIs now explicitly and safely point to your custom DRF views
    path('api/auth/login/', views.login_api, name='login_api'),
    path('api/auth/signup/', views.signup_api, name='signup_api'),
    path('api/books/', views.get_books_api, name='get_books_api'),
    path('api/auth/profile/', views.get_profile_stats_api, name='get_profile_stats_api'),
    path('api/profile/update-book/', views.update_book_status_api, name='update_book_status'),
]

# 👑 ADDED: This instructs Django to serve media file endpoints (like book PDFs) during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)