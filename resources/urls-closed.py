from django.urls import path, include
from . import views
from django.views.generic import TemplateView

app_name = 'social_app'

# Uncomment line 9 and comment line 10 during surveying season
urlpatterns = [
    #path('', TemplateView.as_view(template_name="social_app/index.html"), name='homepage'),
    path('', TemplateView.as_view(template_name="social_app/survey_closed.html"), name='homepage'),
    path('resultats/', TemplateView.as_view(template_name="analytics/index.html"), name='analytics_homepage'),
]
