from rest_framework import viewsets

from computers.models import Computer
from computers.serializers import ComputerSerializer


class SearchViewSet(viewsets.ReadOnlyModelViewSet):
    """ ModelViewSet for Computer model that supports the addition of a search_term query parameter to
    filter the results.
    """
    serializer_class = ComputerSerializer

    def get_queryset(self):
        if search_term := self.request.query_params.get('search_term'):
            return Computer.objects.filter(title__icontains=search_term).all()
        else:
            return Computer.objects.all()
