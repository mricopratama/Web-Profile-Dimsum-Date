<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Menu extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'category',
        'price',
        'description',
        'image_url',
    ];
    public function orders(): BelongsToMany
    {
        return $this->belongsToMany(Order::class, 'order_menu')
                    ->withPivot('quantity', 'price')
                    ->withTimestamps();
    }
}


