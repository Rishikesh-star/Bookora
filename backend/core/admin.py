from django.contrib import admin
# 🚀 Since admin.py is in the same folder as models.py, we import them locally
from .models import Book, UserProfile  

admin.site.register(Book)
admin.site.register(UserProfile)