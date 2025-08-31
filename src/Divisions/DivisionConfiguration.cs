// Copyright (c) 2014-2025 Sarin Na Wangkanai, All Rights Reserved.

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Wangkanai.Nation.Models;

public sealed class DivisionConfiguration : IEntityTypeConfiguration<Division>
{
   public void Configure(EntityTypeBuilder<Division> builder)
   {
      builder.Property(x => x.Iso)
             .HasMaxLength(2)
             .IsRequired();

      builder.Property(x => x.Name)
             .HasMaxLength(100)
             .IsRequired();

      builder.Property(x => x.Native)
             .HasMaxLength(100)
             .IsUnicode()
             .IsRequired();

      builder.HasDiscriminator<string>("type");
   }
}