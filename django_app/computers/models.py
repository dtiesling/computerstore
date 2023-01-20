from django.db import models


class Computer(models.Model):
    """Represents a type of computer that is for sale in the store."""
    vendor = models.TextField()
    title = models.TextField()
    price = models.FloatField(null=True, blank=True)
    striked_price = models.FloatField(null=True, blank=True)
    image_url = models.URLField(null=True, blank=True)

    def __str__(self) -> str:
        return self.description

    class Meta:
        ordering = ['id']
