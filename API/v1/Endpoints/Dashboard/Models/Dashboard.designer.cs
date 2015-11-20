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

namespace API.Endpoints.Dashboard.Models
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
	
	
	[global::System.Data.Linq.Mapping.DatabaseAttribute(Name="MotoApp_v1")]
	public partial class DashboardDataContext : System.Data.Linq.DataContext
	{
		
		private static System.Data.Linq.Mapping.MappingSource mappingSource = new AttributeMappingSource();
		
    #region Extensibility Method Definitions
    partial void OnCreated();
    #endregion
		
		public DashboardDataContext() : 
				base(global::System.Configuration.ConfigurationManager.ConnectionStrings["MotoApp_v1ConnectionString"].ConnectionString, mappingSource)
		{
			OnCreated();
		}
		
		public DashboardDataContext(string connection) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public DashboardDataContext(System.Data.IDbConnection connection) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public DashboardDataContext(string connection, System.Data.Linq.Mapping.MappingSource mappingSource) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public DashboardDataContext(System.Data.IDbConnection connection, System.Data.Linq.Mapping.MappingSource mappingSource) : 
				base(connection, mappingSource)
		{
			OnCreated();
		}
		
		public System.Data.Linq.Table<Filter> Filters
		{
			get
			{
				return this.GetTable<Filter>();
			}
		}
		
		public System.Data.Linq.Table<GraphItem> GraphItems
		{
			get
			{
				return this.GetTable<GraphItem>();
			}
		}
		
		public System.Data.Linq.Table<Counters> Counters
		{
			get
			{
				return this.GetTable<Counters>();
			}
		}
	}
	
	[global::System.Data.Linq.Mapping.TableAttribute(Name="")]
	public partial class Filter
	{
		
		private string _range;
		
		private System.DateTime _start;
		
		private System.DateTime _end;
		
		public Filter()
		{
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_range", CanBeNull=false)]
		public string range
		{
			get
			{
				return this._range;
			}
			set
			{
				if ((this._range != value))
				{
					this._range = value;
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_start")]
		public System.DateTime start
		{
			get
			{
				return this._start;
			}
			set
			{
				if ((this._start != value))
				{
					this._start = value;
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Storage="_end")]
		public System.DateTime end
		{
			get
			{
				return this._end;
			}
			set
			{
				if ((this._end != value))
				{
					this._end = value;
				}
			}
		}
	}
	
	[global::System.Data.Linq.Mapping.TableAttribute(Name="")]
	public partial class GraphItem
	{
		
		private string _label;
		
		private decimal _value;
		
		public GraphItem()
		{
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="Etiqueta", Storage="_label", CanBeNull=false)]
		public string label
		{
			get
			{
				return this._label;
			}
			set
			{
				if ((this._label != value))
				{
					this._label = value;
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUTA_Distancia", Storage="_value", DbType="decimal(18,5)")]
		public decimal value
		{
			get
			{
				return this._value;
			}
			set
			{
				if ((this._value != value))
				{
					this._value = value;
				}
			}
		}
	}
	
	[global::System.Data.Linq.Mapping.TableAttribute(Name="dbo.TB_MOT_Ruta")]
	public partial class Counters
	{
		
		private decimal _distance;
		
		private decimal _speed;
		
		private decimal _calories;
		
		public Counters()
		{
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
					this._distance = value;
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUTA_Velocidad", Storage="_speed", DbType="Decimal(18,5) NOT NULL")]
		public decimal speed
		{
			get
			{
				return this._speed;
			}
			set
			{
				if ((this._speed != value))
				{
					this._speed = value;
				}
			}
		}
		
		[global::System.Data.Linq.Mapping.ColumnAttribute(Name="RUTA_Calorias", Storage="_calories", DbType="Decimal(18,5)")]
		public decimal calories
		{
			get
			{
				return this._calories;
			}
			set
			{
				if ((this._calories != value))
				{
					this._calories = value;
				}
			}
		}
	}
}
#pragma warning restore 1591