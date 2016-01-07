﻿#pragma warning disable 1591
//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.42000
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace API.Endpoints.Routes.Models
{
	using System.Data.Linq;
	using System.Data.Linq.Mapping;
	using System.Data;
	using System.Collections.Generic;
	using System.Reflection;
	using System.Linq;
	using System.Linq.Expressions;
	using System.ComponentModel;
	using System;
	
	
	public partial class DiscoverDataContext : System.Data.Linq.DataContext
	{
		
		private static System.Data.Linq.Mapping.MappingSource mappingSource = new AttributeMappingSource();
		
    #region Extensibility Method Definitions
    partial void OnCreated();
    partial void InsertDiscoveredRoute(DiscoveredRoute instance);
    partial void UpdateDiscoveredRoute(DiscoveredRoute instance);
    partial void DeleteDiscoveredRoute(DiscoveredRoute instance);
    #endregion
		
		public DiscoverDataContext(string connection) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public DiscoverDataContext(System.Data.IDbConnection connection) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public DiscoverDataContext(string connection, System.Data.Linq.Mapping.MappingSource mappingSource) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public DiscoverDataContext(System.Data.IDbConnection connection, System.Data.Linq.Mapping.MappingSource mappingSource) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public System.Data.Linq.Table<Pagination> Paginations
		{
			get
			{
				return this.GetTable<Pagination>();
			}
		}
		
		public System.Data.Linq.Table<DiscoveredRoute> DiscoveredRoutes
		{
			get
			{
				return this.GetTable<DiscoveredRoute>();
			}
		}
	}
	
	[global::System.Data.Linq.Mapping.TableAttribute(Name="")]
	public partial class Pagination
	{
		
		private int _offset;
		
		private int _limit;
		
		private int _total;
		
		public Pagination()
		{
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RegistrosSaltados", Storage="_offset")]
		public int offset
		{
			get
			{
				return this._offset;
			}
			set
			{
				if ((this._offset != value))
				{
					this._offset = value;
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RegistrosPorPagina", Storage="_limit")]
		public int limit
		{
			get
			{
				return this._limit;
			}
			set
			{
				if ((this._limit != value))
				{
					this._limit = value;
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="Contador", Storage="_total")]
		public int total
		{
			get
			{
				return this._total;
			}
			set
			{
				if ((this._total != value))
				{
					this._total = value;
				}
			}
		}
	}
	
	[global::System.Data.Linq.Mapping.TableAttribute(Name="dbo.VT_MOT_RutasPopulares")]
	public partial class DiscoveredRoute : INotifyPropertyChanging, INotifyPropertyChanged
	{
		
		private static PropertyChangingEventArgs emptyChangingEventArgs = new PropertyChangingEventArgs(String.Empty);
		
		private System.Guid _token;
		
		private System.DateTime _createdAt;
		
		private decimal _distance;
		
		private int _duration;
		
		private string _image;
		
		private decimal _proximity;
		
		private string _shared_name;
		
		private int _shared_likes;
		
		private System.DateTime _shared_createdAt;
		
		private System.Guid _creator_token;
		
		private string _creator_identifier;
		
		private string _creator_photo;
		
		private string _fullname;
		
    #region Extensibility Method Definitions
    partial void OnLoaded();
    partial void OnValidate(System.Data.Linq.ChangeAction action);
    partial void OnCreated();
    partial void OntokenChanging(System.Guid value);
    partial void OntokenChanged();
    partial void OncreatedAtChanging(System.DateTime value);
    partial void OncreatedAtChanged();
    partial void OndistanceChanging(decimal value);
    partial void OndistanceChanged();
    partial void OndurationChanging(int value);
    partial void OndurationChanged();
    partial void OnimageChanging(string value);
    partial void OnimageChanged();
    partial void OnproximityChanging(decimal value);
    partial void OnproximityChanged();
    partial void Onshared_nameChanging(string value);
    partial void Onshared_nameChanged();
    partial void Onshared_likesChanging(int value);
    partial void Onshared_likesChanged();
    partial void Onshared_createdAtChanging(System.DateTime value);
    partial void Onshared_createdAtChanged();
    partial void Oncreator_tokenChanging(System.Guid value);
    partial void Oncreator_tokenChanged();
    partial void Oncreator_identifierChanging(string value);
    partial void Oncreator_identifierChanged();
    partial void Oncreator_photoChanging(string value);
    partial void Oncreator_photoChanged();
    partial void Oncreator_fullnameChanging(string value);
    partial void Oncreator_fullnameChanged();
    #endregion
		
		public DiscoveredRoute()
		{
			OnCreated();
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUTA_Token", Storage="_token", DbType="UniqueIdentifier NOT NULL", IsPrimaryKey=true)]
		public System.Guid token
		{
			get
			{
				return this._token;
			}
			set
			{
				if ((this._token != value))
				{
					this.OntokenChanging(value);
					this.SendPropertyChanging();
					this._token = value;
					this.SendPropertyChanged("token");
					this.OntokenChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUTA_Fecha", Storage="_createdAt", DbType="DateTime NOT NULL")]
		public System.DateTime createdAt
		{
			get
			{
				return this._createdAt;
			}
			set
			{
				if ((this._createdAt != value))
				{
					this.OncreatedAtChanging(value);
					this.SendPropertyChanging();
					this._createdAt = value;
					this.SendPropertyChanged("createdAt");
					this.OncreatedAtChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUTA_Distancia", Storage="_distance", DbType="Decimal(18,5) NOT NULL")]
		public decimal distance
		{
			get
			{
				return this._distance;
			}
			set
			{
				if ((this._distance != value))
				{
					this.OndistanceChanging(value);
					this.SendPropertyChanging();
					this._distance = value;
					this.SendPropertyChanged("distance");
					this.OndistanceChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUTA_Duracion", Storage="_duration", DbType="Int NOT NULL")]
		public int duration
		{
			get
			{
				return this._duration;
			}
			set
			{
				if ((this._duration != value))
				{
					this.OndurationChanging(value);
					this.SendPropertyChanging();
					this._duration = value;
					this.SendPropertyChanged("duration");
					this.OndurationChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUTA_Imagen", Storage="_image", DbType="VarChar(2048) NOT NULL", CanBeNull=false)]
		public string image
		{
			get
			{
				return this._image;
			}
			set
			{
				if ((this._image != value))
				{
					this.OnimageChanging(value);
					this.SendPropertyChanging();
					this._image = value;
					this.SendPropertyChanged("image");
					this.OnimageChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="Proximidad", Storage="_proximity")]
		public decimal proximity
		{
			get
			{
				return this._proximity;
			}
			set
			{
				if ((this._proximity != value))
				{
					this.OnproximityChanging(value);
					this.SendPropertyChanging();
					this._proximity = value;
					this.SendPropertyChanged("proximity");
					this.OnproximityChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUCO_Nombre", Storage="_shared_name", DbType="VarChar(500) NOT NULL", CanBeNull=false)]
		public string shared_name
		{
			get
			{
				return this._shared_name;
			}
			set
			{
				if ((this._shared_name != value))
				{
					this.Onshared_nameChanging(value);
					this.SendPropertyChanging();
					this._shared_name = value;
					this.SendPropertyChanged("shared_name");
					this.Onshared_nameChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUCO_MeGusta", Storage="_shared_likes", DbType="Int NOT NULL")]
		public int shared_likes
		{
			get
			{
				return this._shared_likes;
			}
			set
			{
				if ((this._shared_likes != value))
				{
					this.Onshared_likesChanging(value);
					this.SendPropertyChanging();
					this._shared_likes = value;
					this.SendPropertyChanged("shared_likes");
					this.Onshared_likesChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUCO_Fecha", Storage="_shared_createdAt", DbType="DateTime NOT NULL")]
		public System.DateTime shared_createdAt
		{
			get
			{
				return this._shared_createdAt;
			}
			set
			{
				if ((this._shared_createdAt != value))
				{
					this.Onshared_createdAtChanging(value);
					this.SendPropertyChanging();
					this._shared_createdAt = value;
					this.SendPropertyChanged("shared_createdAt");
					this.Onshared_createdAtChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="ENTI_Token", Storage="_creator_token", DbType="UniqueIdentifier NOT NULL")]
		public System.Guid creator_token
		{
			get
			{
				return this._creator_token;
			}
			set
			{
				if ((this._creator_token != value))
				{
					this.Oncreator_tokenChanging(value);
					this.SendPropertyChanging();
					this._creator_token = value;
					this.SendPropertyChanged("creator_token");
					this.Oncreator_tokenChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="ENTI_Identificador", Storage="_creator_identifier", DbType="VarChar(200) NOT NULL", CanBeNull=false)]
		public string creator_identifier
		{
			get
			{
				return this._creator_identifier;
			}
			set
			{
				if ((this._creator_identifier != value))
				{
					this.Oncreator_identifierChanging(value);
					this.SendPropertyChanging();
					this._creator_identifier = value;
					this.SendPropertyChanged("creator_identifier");
					this.Oncreator_identifierChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="ARCH_Token", Storage="_creator_photo", CanBeNull=false)]
		public string creator_photo
		{
			get
			{
				return this._creator_photo;
			}
			set
			{
				if ((this._creator_photo != value))
				{
					this.Oncreator_photoChanging(value);
					this.SendPropertyChanging();
					this._creator_photo = value;
					this.SendPropertyChanged("creator_photo");
					this.Oncreator_photoChanged();
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="USUA_NombreCompleto", Storage="_fullname", DbType="VarChar(250) NOT NULL", CanBeNull=false)]
		public string creator_fullname
		{
			get
			{
				return this._fullname;
			}
			set
			{
				if ((this._fullname != value))
				{
					this.Oncreator_fullnameChanging(value);
					this.SendPropertyChanging();
					this._fullname = value;
					this.SendPropertyChanged("creator_fullname");
					this.Oncreator_fullnameChanged();
				}
			}
		}
		
		public event PropertyChangingEventHandler PropertyChanging;
		
		public event PropertyChangedEventHandler PropertyChanged;
		
		protected virtual void SendPropertyChanging()
		{
			if ((this.PropertyChanging != null))
			{
				this.PropertyChanging(this, emptyChangingEventArgs);
			}
		}
		
		protected virtual void SendPropertyChanged(String propertyName)
		{
			if ((this.PropertyChanged != null))
			{
				this.PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
			}
		}
	}
}
#pragma warning restore 1591