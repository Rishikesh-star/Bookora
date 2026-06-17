from django.db import models

class Book(models.Model):
    title = models.CharField(max_length=255)
    author = models.CharField(max_length=255)
    rating = models.FloatField(default=4.5)
    genres_csv = models.CharField(max_length=255, default="General")
    cover_color = models.CharField(max_length=7, default="#1E88E5")
    created_at = models.DateTimeField(auto_now_add=True)
    cover_image = models.ImageField(upload_to='cover_images/', blank=True, null=True)
    file = models.FileField(upload_to='book_pdfs/', blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = 'core'
        
    def __str__(self):
        return f"{self.title} by {self.author}"
    

from django.contrib.auth.models import User

class UserProfile(models.Model):
   # Links directly to Django's built-in User (handles username, email, password)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    
    # Many-to-Many relationships link users to multiple books dynamically
    favorites = models.ManyToManyField(Book, blank=True, related_name='favorited_by')
    reading_history = models.ManyToManyField(Book, blank=True, related_name='read_by')
    my_library = models.ManyToManyField(Book, blank=True, related_name='in_libraries')

    def __str__(self):
        return f"Profile for {self.user.username}"
    
from django.db.models.signals import post_save
from django.dispatch import receiver

# 🚀 Automatically creates a UserProfile whenever a new User is signed up
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.get_or_create(user=instance)

# 🚀 Automatically updates the profile record when the user updates
@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    if hasattr(instance, 'profile'):
        instance.profile.save()