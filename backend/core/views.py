from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db import IntegrityError
from django.http import JsonResponse
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response 
from rest_framework import status
from .models import Book, UserProfile

# ==========================================
# AUTHENTICATION ENDPOINTS
# ==========================================

@api_view(['POST'])
@permission_classes([AllowAny]) 
def login_api(request):
    try:
        username = request.data.get('username')
        password = request.data.get('password')

        if not username or not password:
            return JsonResponse({'success': False, 'message': 'Username and password are required'}, status=400)

        user = authenticate(username=username, password=password)
        
        if user is not None:
            token, created = Token.objects.get_or_create(user=user)
            return JsonResponse({
                'success': True, 
                'message': 'Login successful',
                'token': token.key,          
                'auth_token': token.key,     
                'username': user.username
            }, status=200)
        else:
            return JsonResponse({'success': False, 'message': 'Invalid credentials'}, status=401)
        
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


@api_view(['POST'])
@permission_classes([AllowAny])
def signup_api(request):
    try:
        username = request.data.get('username')
        password = request.data.get('password')

        if not username or not password:
            return JsonResponse({'success': False, 'message': 'Username and password are required'}, status=400)

        if User.objects.filter(username=username).exists():
            return JsonResponse({'success': False, 'message': 'Username is already taken'}, status=400)

        User.objects.create_user(username=username, password=password)
        return JsonResponse({'success': True, 'message': 'User registered successfully'}, status=201)
        
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)


# ==========================================
# BOOK FEED ENDPOINTS
# ==========================================

@api_view(['GET'])
@permission_classes([AllowAny]) 
def get_books_api(request):
    try:
        books_queryset = Book.objects.all()
        books_list = []
        
        for book in books_queryset:
            parsed_genres = [g.strip() for g in book.genres_csv.split(',') if g.strip()] if book.genres_csv else []
            
            # 👑 Absolute paths for document and image uploads over your Wi-Fi network
            file_url = book.file.url if book.file else None
            image_url = book.cover_image.url if book.cover_image else None

            books_list.append({
                'id': book.id,
                'title': book.title,
                'author': book.author,
                'rating': float(book.rating) if book.rating else 0.0,
                'genres': parsed_genres,
                'cover_color': book.cover_color or '#1C1F2E',
                'file_url': file_url,
                'image_url': image_url,  # 👑 Sent straight to Flutter!
            })
            
        return JsonResponse(books_list, safe=False, status=200)
        
    except Exception as e:
        return JsonResponse({'error': f'Database error: {str(e)}'}, status=500)

# ==========================================
# PROFILE ENDPOINTS
# ==========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_profile_stats_api(request):
    """
    Fetches the customized stats and linked books for the currently authenticated user
    """
    print(f"👉 BACKEND REQUEST USER IS: {request.user} (Authenticated: {request.user.is_authenticated})")
    try:
        profile, created = UserProfile.objects.get_or_create(user=request.user)
        
        def serialize_book_queryset(queryset):
            serialized_list = []
            for book in queryset:
                parsed_genres = [g.strip() for g in book.genres_csv.split(',') if g.strip()] if book.genres_csv else ['General']
                
                # 👑 FIXED: Resolved file and image absolute URLs for custom list sub-routing pipelines too!
                file_url = request.build_absolute_uri(book.file.url) if book.file else None
                image_url = request.build_absolute_uri(book.cover_image.url) if book.cover_image else None
                
                serialized_list.append({
                    'id': book.id,
                    'title': book.title,
                    'author': book.author,
                    'rating': float(book.rating) if book.rating else 4.5,
                    'genres': parsed_genres,
                    'cover_color': book.cover_color or '#1E88E5',
                    'file_url': file_url,
                    'image_url': image_url,  # 👑 Passed down to nested profile lists!
                })
            return serialized_list

        library_list = serialize_book_queryset(profile.my_library.all())
        favorites_list = serialize_book_queryset(profile.favorites.all())

        return JsonResponse({
            'username': request.user.username,
            'email': request.user.email,
            
            'favorites_count': len(favorites_list),
            'library_count': len(library_list),
            
            'my_library_books': library_list,
            'favorites_books': favorites_list,
        }, status=200)

    except Exception as e:
        return JsonResponse({'success': False, 'message': f"Server serialization error: {str(e)}"}, status=500)
    

# ==========================================
# BOOK STATUS UPDATE ENDPOINT
# ==========================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_book_status_api(request):
    """
    Automatically adds or removes a book from a user's library or favorites
    """
    book_id = request.data.get('book_id')
    action = request.data.get('action') # 'library' or 'favorite'
    
    if not book_id or not action:
        return JsonResponse({'success': False, 'message': 'Missing book_id or action'}, status=400)
        
    try:
        book = Book.objects.get(id=book_id)
        profile, created = UserProfile.objects.get_or_create(user=request.user)
        
        if action == 'library':
            if profile.my_library.filter(id=book_id).exists():
                profile.my_library.remove(book)
                message = f"Removed '{book.title}' from your library."
            else:
                profile.my_library.add(book)
                message = f"Added '{book.title}' to your library."
                
        elif action == 'favorite':
            if profile.favorites.filter(id=book_id).exists():
                profile.favorites.remove(book)
                message = f"Removed '{book.title}' from favorites."
            else:
                profile.favorites.add(book)
                message = f"Added '{book.title}' to favorites."
        else:
            return JsonResponse({'success': False, 'message': 'Invalid action'}, status=400)
            
        return JsonResponse({
            'success': True, 
            'message': message,
            'library_count': profile.my_library.count(),
            'favorites_count': profile.favorites.count()
        }, status=200)
        
    except Book.DoesNotExist:
        return JsonResponse({'success': False, 'message': 'Book not found'}, status=404)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=500)