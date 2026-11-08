
from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from core import views

urlpatterns = [
    path('admin/', admin.site.urls),

    path('api/auth/login/', views.login_api, name='login_api'),
    path('api/auth/signup/', views.signup_api, name='signup_api'),
    path('api/books/', views.get_books_api, name='get_books_api'),
    path('api/auth/profile/', views.get_profile_stats_api, name='get_profile_stats_api'),
    path('api/profile/update-book/', views.update_book_status_api, name='update_book_status'),
]

if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT
    )
