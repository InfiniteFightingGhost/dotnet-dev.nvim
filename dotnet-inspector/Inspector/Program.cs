using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using System.Windows.Forms;

// Get the assembly where Windows Forms controls are located
var assembly = typeof(Control).Assembly;

// Find all public types in the assembly that are concrete classes inheriting from Control
var controlTypes = assembly
    .GetTypes()
    .Where(t => t.IsPublic && !t.IsAbstract && typeof(Control).IsAssignableFrom(t))
    .ToList();

var allControls = new List<object>();

foreach (var type in controlTypes)
{
    // Get properties of the control and group them by category
    var propertiesByCategory = TypeDescriptor
        .GetProperties(type)
        .Cast<PropertyDescriptor>()
        .GroupBy(p => p.Category)
        .OrderBy(g => g.Key) // Order categories alphabetically
        .Select(g => new
        {
            Category = g.Key,
            Properties = g.OrderBy(p => p.Name)
                .Select(p => new
                {
                    Name = p.Name,
                    Type = p.PropertyType.FullName,
                    Browsable = p.IsBrowsable,
                    Description = p.Description,
                    DefaultValue = p
                        .Attributes.OfType<DefaultValueAttribute>()
                        .FirstOrDefault()
                        ?.Value,
                    ReadOnly = p.IsReadOnly,
                })
                .ToList(),
        })
        .ToList();

    allControls.Add(
        new
        {
            Name = type.Name,
            FullName = type.FullName,
            Categories = propertiesByCategory,
        }
    );
}

// Serialize the list of controls to a JSON file
var options = new JsonSerializerOptions
{
    WriteIndented = true,
};

File.WriteAllText(
    "../../lua/dotnet-dev/all-components.json",
    JsonSerializer.Serialize(allControls, options)
);

Console.WriteLine(
    $"Successfully inspected {allControls.Count} controls and saved the output to all-components.json"
);
